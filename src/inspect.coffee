require 'coffee-mate/global'
Tail = require('./tail').Tail
fs = require 'fs'
{ls, echo} = require 'shelljs'

currentTime = ->
    (t = new Date).setMinutes(t.getMinutes() - t.getTimezoneOffset())
    t.toISOString().replace('T', ' ').replace('.', ',')[11...-5]

#log_dir = "C:\\Users\\Luo\\Documents\\My Tableau Repository\\Logs\\"
#log_files = [
#    'log.txt'
#    'log_1.txt'
#    'tabprotosrv.txt'
#    'tabprotosrv_1.txt'
#]

homeRoot = str echo('~')
tableauRepos = ls('~/Documents').filter((fname) -> fname.match /\sTableau\s/)
getLogDir = (repoName) -> homeRoot + '\\Documents\\' + repoName + '\\Logs\\'
getLogFileList = (dir_path) ->
    ls(dir_path).filter((fname) -> fname.match /\.txt$/).filter((fname) -> not (fname.match /_bk\.txt$/))

#log -> homeRoot
#log -> tableauRepos
#log -> tableauRepos.map(getLogDir)
#log -> json concat map(combine(getLogFileList) getLogDir) tableauRepos
log 'Tableau Repos:', prettyJson tableauRepos

wrapWithDivider = (msg) -> (proc) ->
    spliter = list(take(msg.length + 3)(repeat '-')).join('')
    console.log spliter
    log.info msg
    do proc
    log.info msg
    console.log spliter

echoQuery = ({repoName, fname, line}) ->
    try log_content = JSON.parse(line)
    if log_content?
        queries = log_content?.v?.jobs?.map((x) -> x['query'] ? x['query-compiled']).filter((x) -> x?)
        if queries? and queries.length > 0
            console.log '\n'
            wrapWithDivider("#{currentTime()} FROM #{fname} (#{repoName})") ->
                console.log '\n'
                for q in queries
                    console.log q, '\n'

lineReaders = list concat tableauRepos.map (repoName) ->
    dirPath = getLogDir(repoName)
    getLogFileList(dirPath).map((fname) -> {repoName, fname, reader: new Tail(dirPath + '\\' + fname)})

startWatch = ->
    lineReaders.forEach ({repoName, fname, reader}) ->
        log "watching #{fname} (#{repoName})"
        reader.on 'line', (line) ->
            echoQuery({repoName, fname, line})

module.exports = {tableauRepos, getLogDir, getLogFileList, startWatch}

if module.parent is null
    do startWatch

