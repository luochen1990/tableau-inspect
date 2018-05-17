events = require("events")
fs = require('fs')

environment = process.env['NODE_ENV'] || 'development'

class Tail extends events.EventEmitter

  readBlock:()=>
    if @queue.length >= 1
      block = @queue.shift()
      if block.end > block.start
        stream = fs.createReadStream(@filename, {start:block.start, end:block.end-1, encoding:"utf-8"})
        stream.on 'error',(error) =>
          @logger.error("Tail error:#{error}") if @logger
          @emit('error', error)
        stream.on 'end',=>
          @internalDispatcher.emit("next") if @queue.length >= 1
        stream.on 'data', (data) =>
          @buffer += data

          parts = @buffer.split(@separator)
          @buffer = parts.pop()
          @emit("line", chunk) for chunk in parts

  constructor:(@filename, options = {}) ->
    super()
    {@separator = /[\r]{0,1}\n/,  @fsWatchOptions = {}, @fromBeginning=false, @follow=true, @logger } = options

    if @logger
      @logger.info("Tail starting:")
      @logger.info("filename:", @filename)

    @buffer = ''
    @internalDispatcher = new events.EventEmitter()
    @queue = []
    @isWatching = false

    @internalDispatcher.on 'next',=>
      @readBlock()

    pos = 0 if @fromBeginning
    @watch(pos)

  watch: (pos) ->
    return if @isWatching
    @isWatching = true
    stats =  fs.statSync(@filename)
    @pos = if pos? then pos else stats.size

    if false #fs.watch
      @watcher = fs.watch @filename, @fsWatchOptions, (e) => @watchEvent e
    else
      fs.watchFile @filename, @fsWatchOptions, (curr, prev) => @watchFileEvent curr, prev

  watchEvent: (e) ->
    if e is 'change'
      stats = fs.statSync(@filename)
      @pos = stats.size if stats.size < @pos #scenario where texts is not appended but it's actually a w+
      if stats.size > @pos
        @queue.push({start: @pos, end: stats.size})
        @pos = stats.size
        @internalDispatcher.emit("next") if @queue.length is 1
    else if e is 'rename'
      @unwatch()
      if @follow
        setTimeout (=> @watch()), 1000
      else
        @logger.error("'rename' event for #{@filename}. File not available.") if @logger
        @emit("error", "'rename' event for #{@filename}. File not available.")

  watchFileEvent: (curr, prev) ->
    if curr.size > prev.size
      @queue.push({start:prev.size, end:curr.size})
      @internalDispatcher.emit("next") if @queue.length is 1

  unwatch: ->
    if fs.watch && @watcher
      @watcher.close()
    else fs.unwatchFile @filename
    @isWatching = false
    @queue = []

exports.Tail = Tail
