-- json lib source: https://gist.github.com/tylerneylon/59f4bcf316be525b30ab
local json = dofile('/fluent-bit/etc/json.lua')

LevelMap = {
  trace = 10,
  debug = 20,
  info = 30,
  warn = 40,
  error = 50,
  fatal = 60
}

Buffer = {}

-- UTILITY FUNCTIONS

function PrintTrace(buffer, trace_id)
  print("trace_id: ", trace_id)
  print(buffer[trace_id]['maxLevel'])
  for k, v in pairs(buffer[trace_id]['logs']) do
    print(k, v['id'], v['url'], v['msg'])
  end
end

function PrintAll(buffer)
  print('printing buffer')
  for trace_id, _ in pairs(buffer) do
    PrintTrace(buffer, trace_id)
  end
  print('done printing')
end

function PersistToDisk(buffer, directory)
  local index = io.open(''..directory..'index.txt', 'w')
  for k, v in pairs(buffer) do
    local file = io.open(''..directory..''..k..'.txt', 'w')
    -- first line is the maxLevel value
    file:write(v['maxLevel'], '\n')
    -- rest of file contains the logs
    for _, log in ipairs(v['logs']) do
      local str = json.stringify(log)
      file:write(str, '\n')
    end
    file:close()
    index:write(k, '\n')
  end
  index:close()
end

function DeleteTrace(buffer, trace_id, directory)
  buffer[trace_id] = nil
  os.remove(''..directory..''..trace_id..'.txt')
end

-- INITIALISATION

function InitBuffer(directory)
  -- read backed-up index from disk
  local index = io.open(''..directory..'index.txt', 'r')
  -- load backups for each unfinished trace
  for trace_id in index:lines() do
    Buffer[trace_id] = {maxLevel=0, logs={}}
    local backupPath = ''..directory..''..trace_id..'.txt'
    local backup = io.open(backupPath , 'r')
    local offset = 0
    for line in backup:lines() do
      if offset == 0 then
        -- first line of every file is reserved for the maxLevel
        Buffer[trace_id]['maxLevel'] = line
      else
        -- remainder of the file contains the actual logs
        Buffer[trace_id]['logs'][offset] = json.parse(line)
      end
      offset = offset + 1
    end
  end

  print('done loading')
end

InitBuffer('/fluent-bit/etc/temp/')
PrintAll(Buffer)

-- FLUENT BIT CALLBACK

function FingersCrossed(tag, timestamp, record)
  local trace_id = record['trace_id']
  local status = record['status']
  local level = LevelMap[record['level']]

  if Buffer[trace_id] == nil then
    Buffer[trace_id] = {maxLevel=level, logs={record}}
  else
    local logs = Buffer[trace_id]['logs']
    local maxLevel = Buffer[trace_id]['maxLevel']
    Buffer[trace_id]['logs'][#logs+1] = record
    Buffer[trace_id]['maxLevel'] = math.max(maxLevel, level)
  end

  -- default: return nothing
  local code = -1
  local record = {}

  -- assume a status means the request has completed
  if status ~= nil then
    if Buffer[trace_id]['maxLevel'] >= 50 then
      code = 1
      record = Buffer[trace_id]['logs']

      print('what we logged')
      PrintTrace(Buffer, trace_id)
    else
      print('what we discarded')
      PrintTrace(Buffer, trace_id)
    end

    -- remove completed trace from the Buffer and disk
    DeleteTrace(Buffer, trace_id, '/fluent-bit/etc/temp/')

    -- back up rest of Buffer contents in case of restart/failure
  end
  PersistToDisk(Buffer, '/fluent-bit/etc/temp/')

  return code, timestamp, record
end
