## http.go

handle http requests from app and other non-time-critical clients.

in case of conflict like network structure that contains loop, when detecte loop, return 400 Bad Request.

## ws.go

handle websocket connection from sub-gateway and clients.