local app_name = "db"
local log = require('log').new(app_name)

box.schema.space.create('sessions', {if_not_exists = true})
box.space.sessions:format({
  { name = "id", type = "unsigned" },
  { name = "users", type = "array" },
  { name = "map", type = "array" },
  { name = "timeLimit", type = "map" },
  { name = "status", type = "integer" },
  { name = "startTime", type = "map", is_nullable = true },
})
box.space.sessions:create_index('id', {parts = { "id" }, if_not_exists = true})

box.schema.space.create('joinedusers', {if_not_exists = true})
box.space.joinedusers:format({
  { name = "userId", type = "unsigned" },
  { name = "sessionId", type = "unsigned" },
})
box.space.joinedusers:create_index('user', {parts = { "userId" }, if_not_exists = true})
box.space.joinedusers:create_index('session', {parts = { "sessionId" }, if_not_exists = true, unique = false})

local function update_users(old, new)
  log.info("updating user-session info in a trigger")
  -- Delete the old users
  if old ~= nil then
    log.info("there is an old state, removing users from it")
    local old_users = box.space.joinedusers.index.session:select({old["id"]})
    for _, uspair in ipairs(old_users) do
      box.space.joinedusers.index.user:delete({uspair[1]})
    end
  end
  
  -- If necessary, insert the new users into the table
  if new["status"] == 0 or new["status"] == 1 then
    log.info("session in new state is alive and well, replacing")
    for _, user in ipairs(new["users"]) do
      box.space.joinedusers:replace({user["Id"], new["id"]})
    end
  end
end

box.space.sessions:on_replace(update_users)

log.info('loaded')
