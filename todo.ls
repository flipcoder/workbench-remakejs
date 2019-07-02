#!/usr/bin/singlefile

export config =
    port: 3000
    base: 'default'
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
                div.app(data-o-save-deep="defaultSave" data-o-type="object")
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
    wsServer = {}
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
        data = deepExtend data, req.body.data
        err <- jsonfile.writeFile fn, data, {spaces:4}
        if err
            console.log 'unable to write json data'
            res.end()
            return

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

    cb['change'] = (data)->
        console.log "send data to client"
        for cl in Object.entries(clients)
            cl[1].res.write(data)

    err, httpServer <- app.run

    #wsServer = new websocket.server do
    #    httpServer: httpServer
    #    autoAcceptConnections: false
    
    #wsServer.on 'request', (req)->
    #    con = request.accept('echo-protocol', request.origin)
    #    #con.on 'message', (msg)->
            
    #    #con.on 'close', (msg)->
    
    console.log 'server running'

