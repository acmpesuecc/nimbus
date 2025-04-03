import os
import strutils
import httpclient, json
import times
import dotenv
import sequtils

load()

type
  Config = object
    pdsHost: string
    handle: string
    appPassword: string

  BlueskyClient = object
    config: Config
    accessJwt: string
    httpClient: HttpClient

  Label = object

  Response = object
    did: string
    handle: string
    displayName: string
    avatar: string
    followersCount: int
    followsCount: int
    postsCount: int
    associated: JsonNode
    createdAt: string
    labels: seq[Label]

# Initialize client
proc initBlueskyClient(): BlueskyClient =
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

  client.httpClient.headers = newHttpHeaders({
      "Content-Type": "application/json"})

  echo "[AUTH]: Auth Token Received."
  return client

# Fetch access token
proc authenticate(client: var BlueskyClient) =
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
  client.accessJwt = authJson["accessJwt"].getStr()

# Prompt user for a message
proc promptForMessage(): string =
  stdout.write("[INFO]: Enter your message: ")
  return readLine(stdin).strip()

# Create a post on Bluesky and display the post link
proc createPost(client: var BlueskyClient, message: string) =
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
proc getPostsFromTimeline(client: BlueskyClient): JsonNode =
  # Get timeline for the current logged in user.
  let timelineUrl = client.config.pdsHost & "/xrpc/app.bsky.feed.getTimeline"
  client.httpClient.headers["Authorization"] = "Bearer " & client.accessJwt
  let timelineResponse = client.httpClient.request(timelineUrl,
      httpMethod = HttpGet)

  if timelineResponse.code != Http200: #Error message in case unable to fetch timeline.
    echo "[ERROR]: Failed to get timeline. Response: " & timelineResponse.body
    return %*{}

  return parseJson(timelineResponse.body)

#Function to resolve the did
proc getDid(client: BlueskyClient, handle: string): string =
  client.httpClient.headers["Authorization"] = "Bearer " & client.accessJwt
  var getDidUri = ""
  if handle != "":
    getDidUri = client.config.pdsHost & "/xrpc/com.atproto.identity.resolveHandle?handle=" & handle
  else:
    getDidUri = client.config.pdsHost & "/xrpc/com.atproto.identity.resolveHandle?handle=" &
        client.config.handle

  let response = client.httpClient.request(getDidUri, httpmethod = HttpGet)
  if response.code == Http200:
    let jsonResponse = parseJson(response.body)
    echo "[SSUCCESS] Got DID!"
    echo jsonResponse["did"].getStr()

    return jsonResponse["did"].getStr()

  else:
    echo "[ERROR] Could not getDID!"
  return "wrongDID"


#Function to get ur repo as carfile
proc getRepo(client: BlueskyClient) =
  # let did = client.didResolve()
  let did = getDid(client, "")

  if did == "wrongDID":
    echo "[ERROR]: Could not resolve DID. Aborting repo fetch."
    return

  client.httpClient.headers["Authorization"] = "Bearer " & client.accessJwt

  let repoUri = client.config.pdsHost & "/xrpc/com.atproto.sync.getRepo?did=" & did


  let response = client.httpClient.request(repoUri, httpMethod = HttpGet)

  if response.code == Http200:
    let filePath = getHomeDir() / "Downloads" / "myRepo.car"
    writeFile(filePath, response.body)
    echo "[SUCCESS]: Your repo is downloaded in the Downloads folder!"

  else:
    echo "[ERROR]: Could not fetch your repo. Error code:", response.code

proc getProfile(client: BlueskyClient, handle: string) =
  let reqUri = "https://public.api.bsky.app/xrpc/app.bsky.actor.getProfile?actor=" & handle
  # echo "[DEBUG] Profile Request URL: ", reqUri
  let response = client.httpClient.request(reqUri)

  if response.code == Http200:
    let userJson = parseJson(response.body)
    let user = to(userJson, Response)

    echo "\n______________________USER PROFILE______________________"
    echo "█ Handle: ", user.handle
    echo "█ Display Name: ", user.displayName
    echo "█ Followers Count: ", user.followersCount
    echo "█ Follows Count: ", user.followsCount
    echo "█ Posts Count: ", user.postsCount
    echo "█ Created At: ", user.createdAt
    echo "____________________________________________"

  else:
    echo "Error fetching profile: ", response.code





when isMainModule:
  var client = initBlueskyClient()
  client.authenticate()

  let args = commandLineParams()

  if args.contains("--post"):
    let message = promptForMessage()
    client.createPost(message)

  elif args.contains("--timeline"):
    let posts = client.getPostsFromTimeline()
    echo "Timeline for user " & client.config.handle & ":"
    echo posts.pretty

  elif args.contains("--help"):
    echo """ 
   
        ███╗░░██╗██╗███╗░░░███╗██████╗░██╗░░░██╗░██████╗ 
        ████╗░██║██║████╗░████║██╔══██╗██║░░░██║██╔════╝ 
        ██╔██╗██║██║██╔████╔██║██████╦╝██║░░░██║╚█████╗░ 
        ██║╚████║██║██║╚██╔╝██║██╔══██╗██║░░░██║░╚═══██╗ 
        ██║░╚███║██║██║░╚═╝░██║██████╦╝╚██████╔╝██████╔╝ 
        ╚═╝░░╚══╝╚═╝╚═╝░░░░░╚═╝╚═════╝░░╚═════╝░╚═════╝░ 
 
        Usage : ./nimbus [--post] [--timeline] [--help] 
 
        To create a post: 
          --post 
         
        To fetch data from timeline: 
          --timeline 
 
        To download your Repo: 
          --getRepo 
 
        To display a handle info: 
          --getProfile-<handle>   //handle without @
 
    """
  elif args.contains("--getRepo"):
    client.getRepo()

  elif args.anyIt(it.startsWith("--getProfile-")):
    for arg in args:
      if arg.startsWith("--getProfile-"):
        let handle = arg[13 .. ^1] # Extracts everything after "--getProfile-"
        getProfile(client, handle)

  else:
    echo "[INFO]: No specific action requested. Use --post or --timeline. Use --help to find out more."
