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

searchRoot = str echo('~/Documents')
tableauRepos = ls(searchRoot).filter((fname) -> fname.match /\sTableau\s/)
getLogDirs = (repoName) ->
    pr = path.join(searchRoot, repoName)
    ps = ['Logs', '日志'].map((s) -> {dirName: s, dirPath: path.join(pr, s)})
    return ps.filter(({dirPath}) -> isDir(dirPath))

getLogFileList = (dir_path) ->
    ls(dir_path).filter((fname) -> fname.match /\.(txt|log)$/).filter((fname) -> not (fname.match /_bk\.txt$/))

#log -> searchRoot
#log -> tableauRepos
#log -> tableauRepos.map(getLogDirs)
log -> tableauRepos

logEvents = do ->
    lineReaders = list concat tableauRepos.map (repoName) ->
        list concat getLogDirs(repoName).map ({dirName, dirPath}) ->
            getLogFileList(dirPath).map (fname) ->
                {repoName, dirName, fname, reader: new Tail(path.join(dirPath, fname))}

    subscribe: (callback) ->
        lineReaders.forEach ({repoName, dirName, fname, reader}) ->
            log "Watching: #{path.join(dirName, fname)} (#{repoName})"
            reader.on 'line', (line) ->
                callback({repoName, dirName, fname, line})

startWatch = ->
    verbose = process.argv.indexOf('-v') >= 0 or process.argv.indexOf('--verbose') >= 0
    log -> verbose

    wrapWithDivider = (msg) -> (proc) ->
        spliter = list(take(msg.length + 3)(repeat '-')).join('')
        console.log spliter
        log.info msg
        do proc
        log.info msg
        console.log spliter

    logEvents.subscribe ({repoName, dirName, fname, line}) ->
        log line if verbose
        if line.indexOf('"query') >= 0
            try logObj = JSON.parse(line)
            if logObj? and logObj.k isnt 'begin-query'
                queries = [logObj.v?['query'], logObj.v?['query-compiled']].concat(logObj.v?.jobs?.map((x) -> x['query'] ? x['query-compiled']) ? []).filter((x) -> x?)
                if queries? and queries.length > 0
                    console.log '\n'
                    wrapWithDivider("#{currentTime()} FROM #{path.join(dirName, fname)} (#{repoName})") ->
                        console.log "\nKey: #{logObj.k ? '?'}; Elapsed: #{logObj.v?.elapsed ? '?'}s\n"
                        for q in queries
                            console.log q, '\n'

module.exports = {tableauRepos, getLogDirs, getLogFileList, startWatch}

if module.parent is null
    do startWatch

