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
        div.note(data-i-editable-with-remove="text(text-single-line)" data-o-type="object" data-o-key-text=note.text data-w-key-text="innerText")
          | #{note.text}
    '''

export client = ->
    remake = require('remakejs/dist/bundle.cjs.js')
    remake.init()
    return

export server = (app)->

    defaults =
        note:
            text: 'New Note'

    jsonfile = require 'jsonfile'
    deepExtend = require 'deep-extend'
    parseUrl = require 'parseurl';
    path = require 'path'
    pug = require 'pug'

    app.get '/', (req,res)->
        console.log '/'
        err, data <- jsonfile.readFile 'data.json'
        if err
            console.log 'unable to load json data'
            res.end()
            return

        res.send pug.renderFile 'views/index.pug', do
            data: data
            params: req.params
            query: req.query
            pathname: parseUrl(req).pathname

    app.post '/save', (req,res)->
        console.log '/save'
        console.log req.body

        fn = path.join(__dirname, 'data.json')
        err, data <- josnfile.readFile fn
        if err
            res.end()
            return
        data = deepExtend data, req.body.data
        err <- json.writeFile fn, data, {spaces:4}

        console.log data

        res.json do
            data: data

    app.post '/new', (req,res)->
        console.log '/new'
        console.log req
        console.log req.body

        templateName = req.body.templateName
        partialPath = path.join(__dirname, "views/" + templateName + ".pug")
        def = {}
        def[templateName] = defaults[templateName]
        htmlString = pug.renderFile partialPath, def
        console.log htmlString

        res.json({htmlString});

    <- app.run
    console.log 'server running'

