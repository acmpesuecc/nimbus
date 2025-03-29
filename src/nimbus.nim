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

  client.httpClient.headers = newHttpHeaders({"Content-Type": "application/json"})

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

# Function to prompt for user handle
proc promptForUserHandle(): string =
  stdout.write("[INFO]: Enter your handle: ")
  return readLine(stdin).strip()

# Function to get posts for a specific user
proc getPostsForUser(client: BlueskyClient, username: string): JsonNode =
  # Resolve handle to DID
  let resolveUrl = client.config.pdsHost & "/xrpc/com.atproto.identity.resolveHandle?handle=" & username
  let resolveResponse = client.httpClient.request(resolveUrl, httpMethod = HttpGet)

  if resolveResponse.code != Http200:
    echo "[ERROR]: Failed to resolve handle " & username & ". Response: " & resolveResponse.body
    return %*{}

  let resolveJson = parseJson(resolveResponse.body)
  let did = resolveJson["did"].getStr()

  # Get timeline for the DID
  let timelineUrl = client.config.pdsHost & "/xrpc/app.bsky.feed.getTimeline?actor=" & did
  client.httpClient.headers["Authorization"] = "Bearer " & client.accessJwt
  let timelineResponse = client.httpClient.request(timelineUrl, httpMethod = HttpGet)

  if timelineResponse.code != Http200:
    echo "[ERROR]: Failed to get timeline for user " & username & ". Response: " & timelineResponse.body
    return %*{}

  return parseJson(timelineResponse.body)

when isMainModule:
  var client = initBlueskyClient()
  client.authenticate()

  # Example usage of the new function:
  let userHandle = promptForUserHandle() & ".bsky.social" # Replace with the desired username/handle
  let posts = client.getPostsForUser(userHandle)
  echo "[INFO]: Posts for user " & userHandle & ":"
  echo posts.pretty