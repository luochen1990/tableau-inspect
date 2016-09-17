require 'coffee-mate/global'
Tail = require('./tail').Tail
fs = require 'fs'
path = require 'path'
{ls, echo} = require 'shelljs'

currentTime = ->
    (t = new Date).setMinutes(t.getMinutes() - t.getTimezoneOffset())
    t.toISOString().replace('T', ' ').replace('.', ',')[11...-5]

isDir = (pth) ->
    try fs.statSync(pth).isDirectory() catch then false

isFile = (pth) ->
    try fs.statSync(pth).isFile() catch then false

#log_dir = "C:\\Users\\Luo\\Documents\\My Tableau Repository\\Logs\\"
#log_files = [
#    'log.txt'
#    'log_1.txt'
#    'tabprotosrv.txt'
#    'tabprotosrv_1.txt'
#]

homeRoot = str echo('~')
tableauRepos = ls('~/Documents').filter((fname) -> fname.match /\sTableau\s/)
getLogDirs = (repoName) ->
    pr = path.join(homeRoot, 'Documents', repoName)
    ps = ['Logs', '日志'].map((s) -> {dirName: s, dirPath: path.join(pr, s)})
    return ps.filter(({dirPath}) -> isDir(dirPath))

getLogFileList = (dir_path) ->
    ls(dir_path).filter((fname) -> fname.match /\.txt$/).filter((fname) -> not (fname.match /_bk\.txt$/))

#log -> homeRoot
#log -> tableauRepos
#log -> tableauRepos.map(getLogDirs)
log 'Tableau Repos:', prettyJson tableauRepos

wrapWithDivider = (msg) -> (proc) ->
    spliter = list(take(msg.length + 3)(repeat '-')).join('')
    console.log spliter
    log.info msg
    do proc
    log.info msg
    console.log spliter

echoQuery = ({repoName, dirName, fname, line}) ->
    try log_content = JSON.parse(line)
    if log_content?
        queries = log_content?.v?.jobs?.map((x) -> x['query'] ? x['query-compiled']).filter((x) -> x?)
        if queries? and queries.length > 0
            console.log '\n'
            wrapWithDivider("#{currentTime()} FROM #{path.join(dirName, fname)} (#{repoName})") ->
                console.log '\n'
                for q in queries
                    console.log q, '\n'

lineReaders = list concat tableauRepos.map (repoName) ->
    list concat getLogDirs(repoName).map ({dirName, dirPath}) ->
        getLogFileList(dirPath).map (fname) ->
            {repoName, dirName, fname, reader: new Tail(path.join(dirPath, fname))}

startWatch = ->
    lineReaders.forEach ({repoName, dirName, fname, reader}) ->
        log "Watching: #{path.join(dirName, fname)} (#{repoName})"
        reader.on 'line', (line) ->
            echoQuery({repoName, dirName, fname, line})

module.exports = {tableauRepos, getLogDirs, getLogFileList, startWatch}

if module.parent is null
    do startWatch

