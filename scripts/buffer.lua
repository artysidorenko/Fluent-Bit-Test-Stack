levelMap = {
  trace = 10,
  debug = 20,
  info = 30,
  warn = 40,
  error = 50,
  fatal = 60
}

-- variable is kept in global memory
buffer = {}

function fingers_crossed(tag, timestamp, record)

  local trace_id = record['trace_id']
  local status = record['status']
  local level = levelMap[record['level']]

  if buffer[trace_id] == nil then
    buffer[trace_id] = {maxLevel=level, logs={record}}
  else
    local logs = buffer[trace_id]['logs']
    local maxLevel = buffer[trace_id]['maxLevel']
    buffer[trace_id]['logs'][#logs+1] = record
    buffer[trace_id]['maxLevel'] = math.max(maxLevel, level)
  end

  -- default: return nothing
  local code = -1
  local record = {}

  -- assume a status means the request has completed
  if status ~= nil then
    if buffer[trace_id]['maxLevel'] >= 50 then
      code = 1
      record = buffer[trace_id]['logs']

      print('what we logged')
      print_trace(trace_id)
    else
      print('what we discarded')
      print_trace(trace_id)
    end

  end

  return code, timestamp, record
end

-- for internal use only: print contents of the trace array:
function print_trace(trace_id)
  print("trace_id: ", trace_id)
  print(buffer[trace_id]['maxLevel'])
  for k, v in pairs(buffer[trace_id]['logs']) do
    print(k, v['id'], v['url'], v['msg'])
  end
end
