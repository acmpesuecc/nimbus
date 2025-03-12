import os
import strutils
import httpclient, json
import times
import dotenv

load()

type BlueskyClient = object
  pdsHost: string
  handle: string
  appPassword: string
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

  var client = BlueskyClient(
    pdsHost: pdsHost,
    handle: handle,
    appPassword: appPassword,
    accessJwt: "",
    httpClient: newHttpClient()
  )
  client.httpClient.headers = newHttpHeaders({"Content-Type": "application/json"})
  return client


# Fetch access token
proc authenticate(client: var BlueskyClient) =
  let authPayload = %*{
    "identifier": client.handle,
    "password": client.appPassword
  }

  let authResponse = client.httpClient.request(
    client.pdsHost & "/xrpc/com.atproto.server.createSession",
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
    "repo": client.handle,
    "collection": "app.bsky.feed.post",
    "record": %*{
      "text": message,
      "createdAt": format(now(), "yyyy-MM-dd'T'HH:mm:ss'Z'")
    }
  }

  let postResponse = client.httpClient.request(
    client.pdsHost & "/xrpc/com.atproto.repo.createRecord",
    httpMethod = HttpPost,
    body = postPayload.pretty
  )

  if postResponse.code != Http200:
    quit("[ERROR]: Failed to create post. Response: " & postResponse.body, 1)

  let postJson = parseJson(postResponse.body)
  let uri = postJson["uri"].getStr()
  let postId = uri.split("/")[^1]

  echo "[INFO]: Post successful: https://bsky.app/profile/" & client.handle &
      "/post/" & postId

when isMainModule:
  var client = initBlueskyClient()
  client.authenticate()
  let message = promptForMessage()
  client.createPost(message)

