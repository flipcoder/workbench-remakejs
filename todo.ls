#!/usr/bin/singlefile

export config =
    port: 3000

export npm =
    name: 'todo'
    dependencies:
        jsonfile: '*'
        parseurl: '*'
        remakejs: '*'
        livescript: '*'
        uuid: '*'
        'connect-timeout': '*'
        'deep-extend': '*'

export views =
    'index.pug': '''
        doctype html
        html
            head
            body
                div.app(data-o-save-deep="defaultSave" data-id=id data-timestamp=timestamp data-o-type="object")
                    h1 Notes
                    button(data-i-new="note .notes") New
                    div.notes(data-o-key="notes" data-o-type="list")
                        each note in data.notes
                            include note
                    br
                script(src="client.js")
    ''',
    'note.pug': '''
        div.note(data-i-editable-with-remove="text(text-single-line)" data-o-type="object" data-o-key-text=note.text data-id=note.id data-w-key-text="innerText")
            | #{note.text}
    '''

export client = ->
    remake = require('remakejs/dist/bundle.cjs.js')
    remake.init()

export server = (app)->

    defaults =
        note:
            text: 'New Note'

    jsonfile = require 'jsonfile'
    deepExtend = require 'deep-extend'
    parseUrl = require 'parseurl';
    path = require 'path'
    pug = require 'pug'
    uuid = require 'uuid/v4'
    #websocket = require 'websocket'
    #wsServer = {}
    clients = []
    cb = {}
    timeout = require('connect-timeout')

    app.use(timeout(0))

    app.get '/', (req,res)->
        console.log '/'
        fn = path.join(__dirname, 'data.json')
        err, data <- jsonfile.readFile fn
        if err
            console.log 'unable to load json data'
            res.end()
            return

        res.send pug.renderFile path.join(__dirname,'views/index.pug'), do
            data: data
            params: req.params
            query: req.query
            pathname: parseUrl(req).pathname

    app.post '/save', (req,res)->
        console.log '/save'
        console.log req.body.data

        fn = path.join(__dirname, 'data.json')
        err, data <- jsonfile.readFile fn
        if err
            console.log 'unable to load json data'
            res.end()
            return
        client_ts = req.body['timestamp']
        if client_ts
            if client_ts < data['timestamp'] # server ts is more current?
                res.write('!') # force client to repull
                res.end()
        data = deepExtend data, req.body.data

        data['timestamp'] = Date.now()
        err <- jsonfile.writeFile fn, data, {spaces:4}
        if err
            console.log 'unable to write json data'
            res.end()
            return

        # TODO: look through data, trigger change listeners for IDs?

        # TODO: it the structure of the data has changed, restructure

        # trigger notification of change to listening clients
        cb['change'](JSON.stringify(data))

        console.log data

        res.json do
            data: data

    app.post '/new', (req,res)->
        console.log '/new'
        #console.log req.body

        templateName = req.body.templateName
        partialPath = path.join(__dirname, "views/" + templateName + ".pug")
        def = {}
        def[templateName] = defaults[templateName]
        def[templateName]['id'] = uuid()
        console.log def
        htmlString = pug.renderFile partialPath, def
        #console.log htmlString

        res.json({htmlString});

    app.post '/listen', (req,res)->
        console.log 'client connected'
        cid = uuid()
        req.connection.on 'disconnect', ->
            delete clients[cid]
        clients[cid] = { req: req, res: res }

    # change callback
    cb['change'] = (data)->
        console.log "send data to client"
        str = pug.renderFile path.join(__dirname,'views/index.pug'), do
            data: JSON.parse(data)
        
        console.log str
        
        for cl in Object.entries(clients)
            cl[1].res.write str

    err, httpServer <- app.run

    #wsServer = new websocket.server do
    #    httpServer: httpServer
    #    autoAcceptConnections: false
    
    #wsServer.on 'request', (req)->
    #    con = request.accept('echo-protocol', request.origin)
    #    #con.on 'message', (msg)->
            
    #    #con.on 'close', (msg)->
    
    console.log 'server running'

