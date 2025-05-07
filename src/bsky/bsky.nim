import os
import strutils
import httpclient, json
import times
import dotenv

load()

type
  Config* = object
    pdsHost: string
    handle: string
    appPassword: string

  BlueskyClient* = object
    config: Config
    accessJwt: string
    httpClient: HttpClient

# Initialize client
proc initBlueskyClient*(): BlueskyClient =
  # Get required environment variables
  let pdsHost = getEnv("PDSHOST", "https://bsky.social")
  let handle = getEnv("BLUESKY_HANDLE", "")
  let appPassword = getEnv("APP_PASSWORD", "")
  if handle == "" or appPassword == "":
    quit("[ERROR]: BLUESKY_HANDLE or APP_PASSWORD is missing from .env file", 1)

  let config = Config(
    pdsHost: pdsHost,
    handle: handle,
    appPassword: appPassword,
  )

  var client = BlueskyClient(
    config: config,
    accessJwt: "",
    httpClient: newHttpClient()
  )

  client.httpClient.headers = newHttpHeaders({"Content-Type": "application/json"})

  echo "[AUTH]: Auth Token Received."
  return client

# Fetch access token
proc authenticate*(client: var BlueskyClient) =
  let authPayload = %*{
    "identifier": client.config.handle,
    "password": client.config.appPassword
  }

  let authResponse = client.httpClient.request(
    client.config.pdsHost & "/xrpc/com.atproto.server.createSession",
    httpMethod = HttpPost,
    body = authPayload.pretty
  )

  if authResponse.code != Http200:
    quit("[ERROR]: Failed to authenticate. Response: " & authResponse.body, 1)

  let authJson = parseJson(authResponse.body)
  client.accessJwt =  authJson["accessJwt"].getStr()

# Prompt user for a message
proc promptForMessage(): string =
  stdout.write("[INFO]: Enter your message: ")
  return readLine(stdin).strip()

# Create a post on Bluesky and display the post link
proc createPost(client: var BlueskyClient,  message: string) =
  client.httpClient.headers["Authorization"] = "Bearer " & client.accessJwt

  let postPayload = %*{
    "repo": client.config.handle,
    "collection": "app.bsky.feed.post",
    "record": %*{
      "text": message,
      "createdAt": format(now(), "yyyy-MM-dd'T'HH:mm:ss'Z'")
    }
  }

  let postResponse = client.httpClient.request(
    client.config.pdsHost & "/xrpc/com.atproto.repo.createRecord",
    httpMethod = HttpPost,
    body = postPayload.pretty
  )

  if postResponse.code != Http200:
    quit("[ERROR]: Failed to create post. Response: " & postResponse.body, 1)

  let postJson = parseJson(postResponse.body)
  let uri = postJson["uri"].getStr()
  let postId = uri.split("/")[^1]

  echo "[INFO]: Post successful: https://bsky.app/profile/" & client.config.handle &
       "/post/" & postId

# Function to get data from user timeline
proc getPostsFromTimeline*(client: BlueskyClient): JsonNode =
  # Get timeline for the current logged in user. (By logged in I mean the creds on the .env file)
  let timelineUrl = client.config.pdsHost & "/xrpc/app.bsky.feed.getTimeline"
  client.httpClient.headers["Authorization"] = "Bearer " & client.accessJwt
  let timelineResponse = client.httpClient.request(timelineUrl, httpMethod = HttpGet)

  if timelineResponse.code != Http200: #Error message in case unable to fetch timeline.
    echo "[ERROR]: Failed to get timeline. Response: " & timelineResponse.body
    return %*{}

  return parseJson(timelineResponse.body)

# Function to prompt for user handle
proc promptForUserHandle(): string =
  stdout.write("[INFO]: Enter user handle: ")
  return readLine(stdin).strip()

proc resolveDID(client:BlueskyClient, userhandle:string): string=
  #resolves handle to did using [https://docs.bsky.app/docs/api/com-atproto-identity-resolve-handle]
  let resolveUrl = client.config.pdsHost & "/xrpc/com.atproto.identity.resolveHandle?handle=" & userHandle
  let resolveResponse = client.httpClient.request(resolveUrl, httpMethod = HttpGet)
  if resolveResponse.code != Http200:
    echo "[ERROR]: Failed to resolve handle " & userHandle & ". Response: " & resolveResponse.body
    return ""
  let resolveJson = parseJson(resolveResponse.body)
  let did = resolveJson["did"].getStr()
  return did

# Function to get all posts by a user handle
proc getAllPostsByUser*(client: BlueskyClient, userHandle: string): seq[JsonNode] =
  var allPosts: seq[JsonNode]
  let did = resolveDID(client,userHandle)

  # Get posts for the DID using listRecords [https://docs.bsky.app/docs/api/com-atproto-repo-list-records]
  let listRecordsUrl = client.config.pdsHost & "/xrpc/com.atproto.repo.listRecords?repo=" & did & "&collection=app.bsky.feed.post&limit=100" #TODO: rn i set limit to 100, later might have to adjust this dynamically
  client.httpClient.headers["Authorization"] = "Bearer " & client.accessJwt

  let listRecordsResponse = client.httpClient.request(
    listRecordsUrl,
    httpMethod = HttpGet
  )

  if listRecordsResponse.code != Http200:
    echo "[ERROR]: Failed to get posts for user " & userHandle & ". Response: " & listRecordsResponse.body
    return @[]

  let listRecordsJson = parseJson(listRecordsResponse.body)

  if listRecordsJson.hasKey("records") and listRecordsJson["records"].kind == JArray:
    for record in listRecordsJson["records"].elems:
      if (record.kind == JObject ) and ( record.hasKey("value") ):
        allPosts.add(record["value"])
  else:
    echo "[ERROR]: Can't find records in list-records, this might mean that the person has not posted anything, or some err idk 🤷🏼‍♂️"

  return allPosts

# Function to get all accounts a user is following
proc getAllFollowing*(client: BlueskyClient, userHandle: string): seq[JsonNode] =
  # Resolve the handle to DID using the same resolveDID function
  let did = resolveDID(client, userHandle)
  
  if did == "":
    echo "[ERROR]: Invalid DID resolution. Cannot fetch following accounts."
    return @[]

  # Get Handles of followers using followingURL  [https://docs.bsky.app/docs/api/app-bsky-graph-get-follows]
  let followingUrl = client.config.pdsHost & "/xrpc/app.bsky.graph.getFollows?actor=" & did
  client.httpClient.headers["Authorization"] = "Bearer " & client.accessJwt

  let followingResponse = client.httpClient.request(
    followingUrl,
    httpMethod = HttpGet
  )

  if followingResponse.code != Http200:
    echo "[ERROR]: Failed to get following accounts for user " & userHandle & ". Response: " & followingResponse.body
    return @[]

  let followingJson = parseJson(followingResponse.body)

  var following: seq[JsonNode]
  
  if followingJson.hasKey("follows") and followingJson["follows"].kind == JArray:
    for follow in followingJson["follows"].elems:
      following.add(follow)
  else:
    echo "[ERROR]: Can't find following accounts in the response."

  return following

#function to search for posts/users, use "@xyz" to search for an user and "xyz" to search for posts . Eg: @mebin.in
proc search*(client: var BlueskyClient,keyword: string): seq[JsonNode] = 
    
    client.httpClient.headers["Authorization"] = "Bearer " & client.accessJwt
    
    var searchUrl: string
    
    let splitWords = keyword.splitWhitespace()
    
    let startingLetter = keyword.startsWith("@")

    case startingLetter
      of true:
        let splitWordsUser = keyword[1..^1].splitWhitespace()
        let query = join(splitWordsUser,"+")
        searchUrl = "https://public.api.bsky.app/xrpc/app.bsky.actor.searchActors?q=" & query
        
      of false:
        let query = join(splitWords,"+") 
        searchUrl = "https://bsky.social/xrpc/app.bsky.feed.searchPosts?q=" & query & "&limit=25&sort=top" #for now just the top 25 results
        
    let searchResponse = client.httpClient.request(
            searchUrl,
            httpMethod = HttpGet
          )  

    if searchResponse.code != Http200:
        echo "[ERROR]: Failed to get Users/Posts, response: " & searchResponse.body    #i feel like i shld hv done better error handling
        return @[]

    let searchJson = parseJson(searchResponse.body)

    var searchResults: seq[JsonNode]
      
    if searchJson.hasKey("actors") and searchJson["actors"].kind == JArray and searchJson["actors"].len!=0:
        for user in searchJson["actors"].elems:
          searchResults.add(user)
    elif searchJson.hasKey("posts") and searchJson["posts"].kind == JArray and searchJson["posts"].len!=0:
        for post in searchJson["posts"].elems:
          searchResults.add(post)
    else:
        echo "[ERROR]: Failed to retrieve users/posts"
        return @[]

    return searchResults

# Putting the initilization outside so that if the functions of this file are called,
# Authentication is done first.
var client = initBlueskyClient()
client.authenticate()
when isMainModule:

  let args = commandLineParams()

  if args.contains("--post"):
    let message = promptForMessage()
    client.createPost(message)

  elif args.contains("--timeline"):
    let posts = getPostsFromTimeline(client)
    echo "Timeline for user " & client.config.handle & ":"
    echo posts.pretty

  elif args.contains("--user-posts"):
    let userHandle = promptForUserHandle()
    let posts = client.getAllPostsByUser(userHandle)
    echo "\n\nPosts by user " & userHandle & ":"
    for post in posts:
      echo "\nText: " & post["text"].getStr()
      echo "Created at: " & post["createdAt"].getStr()
      echo "--- \n"
  
  elif args.contains("--user-following"):
    let following = client.getAllFollowing(client.config.handle)
    echo "\nAccounts that " & client.config.handle & " is following:"
    for account in following:
        echo "Following: " & account["displayName"].getStr()
        echo "Handle: " & account["handle"].getStr()
        echo "--- \n"

  elif args.contains("--following-posts"):
    let following = client.getAllFollowing(client.config.handle)

    for account in following:
      let userHandle = account["handle"].getStr()
      echo "\n[INFO]: Fetching posts from " & account["displayName"].getStr() & " (@" & userHandle & ")"
      let posts = client.getAllPostsByUser(userHandle)

      if posts.len == 0:
        echo "  No posts found or error occurred."
      else:
        for post in posts:
          echo "\n  Text: " & post["text"].getStr()
          echo " Created at: " & post["createdAt"].getStr()
          echo "  ---"
          
  elif args.contains("--search"):
      let searchQuery = join(args[1..^1]," ")
      let searchResults = client.search(searchQuery)

      if searchResults == @[]:
          raise newException(IndexDefect,"No users or posts found") #raises indexDefect error if no users or posts found
      
      if searchResults[0].hasKey("uri"):
          echo "Fetching " & $searchResults.len & " posts \n"
          for post in searchResults:
            let handle = post["author"]["handle"].getStr()
            let displayName = post["author"]["displayName"].getStr()
            let commentBody = post["record"]["text"].getStr()
            let commentCount = $post["replyCount"]
            let likeCount = $post["likeCount"]
            echo "handle: " & handle & " displayName: " & displayName & "\n" & "comment: " & commentBody & "\n" & "commentCount: " & commentCount & " likecount: " & likeCount
            echo "\n"
      
      elif searchResults[0].hasKey("did"):
          echo "Fetching: " & $searchResults.len & " users \n"
          for user in searchResults:
              let handle = user["handle"].getStr()
              let displayName = user["displayName"].getStr()
              echo "handle: " & handle & " displayName: " & displayName & "\n"
    
    
  
  elif args.contains("--help"):
    echo """
  
        ███╗░░██╗██╗███╗░░░███╗██████╗░██╗░░░██╗░██████╗
        ████╗░██║██║████╗░████║██╔══██╗██║░░░██║██╔════╝
        ██╔██╗██║██║██╔████╔██║██████╦╝██║░░░██║╚█████╗░
        ██║╚████║██║██║╚██╔╝██║██╔══██╗██║░░░██║░╚═══██╗
        ██║░╚███║██║██║░╚═╝░██║██████╦╝╚██████╔╝██████╔╝
        ╚═╝░░╚══╝╚═╝╚═╝░░░░░╚═╝╚═════╝░░╚═════╝░╚═════╝░

        Usage : ./nimbus [--post] [--timeline] [--user-posts] [--user-following] [--following-posts] [--help]

        To create a post:
          --post
        
        To fetch data from timeline:
          --timeline

        To fetch all posts by a specific user:
          --user-posts

        To fetch all accounts followed by user:
          --user-following

        To fetch all posts by the accounts followed by user
          --following-posts

    """
  else:
    echo "[INFO]: No specific action requested. Use --post, --timeline, --user-posts, --user-following or --following-posts. Use --help to find out more."
  