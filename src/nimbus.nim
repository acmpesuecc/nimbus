import os
import strutils
import httpclient, json
import times
import dotenv

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
proc getDid(client: BlueskyClient): string =
  client.httpClient.headers["Authorization"] = "Bearer " & client.accessJwt
  let getDidUri = client.config.pdsHost &
      "/xrpc/com.atproto.identity.resolveHandle?handle=" & client.config.handle
  let response = client.httpClient.request(getDidUri, httpmethod = HttpGet)
  if response.code == Http200:
    let jsonResponse = parseJson(response.body)
    echo "[SSUCCESS] Got DID!"
    return jsonResponse["did"].getStr()

  else:
    echo "[ERROR] Could not getDID!"
  return "wrongDID"




#Function to get ur repo as carfile
proc getRepo(client: BlueskyClient) =
  # let did = client.didResolve()
  let did = client.getDid()
  let repoUri = client.config.pdsHost & "/xrpc/com.atproto.sync.getRepo?did=" & did
  client.httpClient.headers["Authorization"] = "Bearer " & client.accessJwt
  let response = client.httpClient.request(repoUri, httpMethod = HttpGet)

  if response.code == Http200:
    let filePath = getHomeDir() / "Downloads" / "myRepo.car"
    writeFile(filePath, response.body)
    echo "[SUCCESS]: Your repo is downloaded in the Downloads folder!"
  else:
    echo "[ERROR]: Could not fetch your repo. Error code:", response.code

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

    """
  elif args.contains("--getRepo"):
    client.getRepo()
  else:
    echo "[INFO]: No specific action requested. Use --post or --timeline. Use --help to find out more."
