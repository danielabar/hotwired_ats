<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [README](#readme)
  - [Chapter 1](#chapter-1)
    - [The Stack](#the-stack)
    - [Creating a Rails application with rails new](#creating-a-rails-application-with-rails-new)
    - [Configure Tailwind](#configure-tailwind)
    - [Update esbuild config](#update-esbuild-config)
    - [Update bin/dev Scripts](#update-bindev-scripts)
    - [Install CableReady, StimulusReflex, and Mrujs](#install-cableready-stimulusreflex-and-mrujs)
  - [Chapter 2](#chapter-2)
    - [Users and accounts with Devise](#users-and-accounts-with-devise)
    - [Tailwind](#tailwind)
    - [Stimulus](#stimulus)
  - [Chapter 3: Job Postings](#chapter-3-job-postings)
    - [Creating jobs in a slideover](#creating-jobs-in-a-slideover)
    - [Creating job postings](#creating-job-postings)
    - [Slideover edit links](#slideover-edit-links)
    - [Deleting jobs](#deleting-jobs)
    - [Adding jobs with Turbo Streams](#adding-jobs-with-turbo-streams)
  - [My Questions and Comments](#my-questions-and-comments)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# README

Learning Rails with the Hotwire stack, CableReady, and StimulusReflex with [this book](https://book.hotwiringrails.com/chapters). Github [repo](https://github.com/DavidColby/hotwired_ats_code).

```
docker-compose up
bin/rails db:create
bin/dev
```

## Chapter 1

### The Stack

* [esbuild](https://esbuild.github.io/) for bundling JS. Will configure to auto refresh browser as changes are made to any JS or CSS.
  * [chokidar](https://github.com/paulmillr/chokidar) Minimal and efficient cross-platform file watching library.
* [Tailwind](https://tailwindcss.com/) and postcss for styling.
  * [postcss-import](https://www.npmjs.com/package/postcss-import) npm/yarn module, PostCSS plugin to transform @import rules by inlining content.
  * [tailwindcss-forms](https://github.com/tailwindlabs/tailwindcss-forms) Tailwind plugin that provides a basic reset for form styles that makes form elements easy to override with utilities.
* [Hotwire stack](https://hotwired.dev/) for faster page loads:
  * [Turbo Drive](https://turbo.hotwired.dev/handbook/drive) watches for link clicks and form submissions and performs them in the background, then updates the page without doing a full reload. Evolution of `turbolinks` gem.
  * [Turbo Frames](https://turbo.hotwired.dev/handbook/frames) for partial page updates. Any links and forms inside a frame are captured, and the frame contents automatically updated after receiving a response. Regardless of whether the server provides a full document, or just a fragment containing an updated version of the requested frame, only that particular frame will be extracted from the response to replace the existing content
  * [Turbo Streams](https://turbo.hotwired.dev/handbook/streams) for reactive page updates. Delivers page changes as fragments of HTML wrapped in self-executing `<turbo-stream>` elements. Each stream element specifies an action together with a target ID to declare what should happen to the HTML inside it. These elements are delivered by the server over a WebSocket, [SSE](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events) or other transport to bring the application alive with updates made by other users or processes.
  * [Stimulus](https://stimulus.hotwired.dev/handbook/introduction) for front end interactivity. Enhances static or server-rendered HTML—the “HTML you already have”—by connecting JavaScript objects to elements on the page using simple annotations.
* [CableReady](https://cableready.stimulusreflex.com/) further server-powered frontend interactivity and reactive page updates. Triggers client-side DOM changes, events and notifications over ActionCable web sockets. These commands are called [operations](https://cableready.stimulusreflex.com/reference/operations). CableReady is the primary dependency powering StimulusReflex (see below). Establishes a standard for programmatically updating browser state with no need for custom JavaScript.
* [StimulusReflex](https://docs.stimulusreflex.com/) works together with CableReady. Extends the capabilities of both Rails and Stimulus by intercepting user interactions and passing them to Rails over real-time websockets. These interactions are processed by Reflex actions that change application state. The current page is quickly re-rendered and the changes are sent to the client using CableReady. The page is then [morphed](https://github.com/patrick-steele-idem/morphdom) to reflect the new application state. This entire round-trip allows us to update the UI in 20-30ms without flicker or expensive page loads.
* [mrujs](https://mrujs.com/) Sprinkle interactivity into your HTML elements using data attributes. A replacement for `@rails/ujs`, which used to ship by default with Rails 6 but has since been deprecated.
* [CableCar](https://cableready.stimulusreflex.com/v/v5/cable-car) An Mrujs [plugin](https://mrujs.com/how-tos/integrate-cablecar) for use with CableReady's JSON serializer. CableReady was originally created to only work over ActionCable (aka websockets). With CableCar, operation queueing can also work over Ajax.

All form POST requests are automatically having header set `Accept: text/vnd.turbo-stream.html, text/html, application/xhtml+xml`, which makes Rails controller process request as turbo stream, eg: `Processing by JobsController#create as TURBO_STREAM`. Where is this configured to do so?

According to ChatGPT on turbo streams:

> The "TURBO_STREAM" format is a way of streaming responses in Rails. It allows the server to send a response to the client in chunks, rather than waiting for the entire response to be generated before sending it. This can be useful for large responses or for responses that take a long time to generate, as it allows the client to start receiving and rendering the response before the entire response has been generated.

> The line "Processing by JobsController#create as TURBO_STREAM" indicates that a request is being processed by the create action in the JobsController controller, and that the response will be sent using the "TURBO_STREAM" format.

According to ChatGPT on difference between Stimulus and StimulusReflex:

> Stimulus is a JavaScript library for adding interactivity to your web application. It is designed to be lightweight and easy to use, and it allows you to add behaviors to your HTML elements using simple JavaScript classes.

> StimulusReflex is an extension of Stimulus that adds real-time, server-side rendering to your application. It uses the ActionCable websocket framework to allow the server to push updates to the client without the need for the client to constantly poll the server for updates. This can be useful for building responsive, interactive applications without the need for complex client-side code.

> One key difference between Stimulus and StimulusReflex is that Stimulus is focused on adding client-side behaviors to your application, while StimulusReflex adds real-time, server-side rendering capabilities. This means that Stimulus is primarily used for adding interactions and animations to your application, while StimulusReflex is used for updating the application's state and rendering new content in real-time.

### Creating a Rails application with rails new

Specify tailwind for css and esbuild for javascript handling. `-T` skips tests as we won't be focusing on that in this book:

```
rails new hotwired_ats -T --css=tailwind --javascript=esbuild
cd hotwired_ats
rails db:create
```

### Configure Tailwind

[cssbundling-rails](https://github.com/rails/cssbundling-rails) gem doesn't support importing other css files into [app/assets/stylesheets/application.tailwind.css](app/assets/stylesheets/application.tailwind.css). Fix with some additional install and config:

```
yarn add postcss-import
touch postcss.config.js
```

```javascript
// postcss.config.js
module.exports = {
  plugins: [
    require('postcss-import'),
    require('tailwindcss'),
    require('autoprefixer')
  ]
}
```

```css
/* app/assets/stylesheets/application.tailwind.css */
@import "tailwindcss/base";
@import "tailwindcss/components";
@import "tailwindcss/utilities";
```

### Update esbuild config

[jsbundling-rails]([https://github.com/rails/jsbundling-rails]) gem sets up extremely simple esbuild config, but will almost always need to customize it.

Our custom config should do the following:

* Enable source maps in dev and prod.
* Minify bundle in prod.
* Auto rebuild/refresh page when assets and view files change.

Install [chokidar](https://github.com/paulmillr/chokidar) for file watching and auto refresh, then configure esbuild:

```
yarn add chokidar -D
touch esbuild.config.js
```

```javascript
// esbuild.config.js
#!/usr/bin/env node

const esbuild = require('esbuild')
const path = require('path')

// Add more entrypoints, if needed
const entryPoints = [
  "application.js",
]
const watchDirectories = [
  "./app/javascript/**/*.js",
  "./app/views/**/*.html.erb",
  "./app/assets/stylesheets/*.css",
  "./app/assets/stylesheets/*.scss"
]

const config = {
  absWorkingDir: path.join(process.cwd(), "app/javascript"),
  bundle: true,
  entryPoints: entryPoints,
  outdir: path.join(process.cwd(), "app/assets/builds"),
  sourcemap: true
}

async function rebuild() {
const chokidar = require('chokidar')
const http = require('http')
const clients = []

http.createServer((req, res) => {
  return clients.push(
    res.writeHead(200, {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache",
      "Access-Control-Allow-Origin": "*",
      Connection: "keep-alive",
    }),
  );
}).listen(8082);

let result = await esbuild.build({
  ...config,
  incremental: true,
  banner: {
    js: ' (() => new EventSource("http://localhost:8082").onmessage = () => location.reload())();',
  },
})

chokidar.watch(watchDirectories).on('all', (event, path) => {
  if (path.includes("javascript")) {
    result.rebuild()
  }
  clients.forEach((res) => res.write('data: update\n\n'))
  clients.length = 0
});
}

if (process.argv.includes("--rebuild")) {
  rebuild()
} else {
  esbuild.build({
    ...config,
    minify: process.env.RAILS_ENV == "production",
  }).catch(() => process.exit(1));
}
```

**Notes**

* `reload` function creates a web server listening on 8082 and builds JS with esbuild and uses [banner](https://esbuild.github.io/api/#banner) option.
* banner option inserts JS into the built file that opens an [EventSource](https://developer.mozilla.org/en-US/docs/Web/API/EventSource) connection to server on 8082 and fires `reload` each time message is received.
* chokidar watches directories containing our custom js, css and erb, then broadcasts a message to EventSource server, which triggers `reload()` on browser and tells esbuild to rebuild JS (if change was detected in any JS files)
* rebuild used for dev, `esbuild.build()` used for prod.

### Update bin/dev Scripts

Update scripts in package.json that are called from `yarn` cli (but we never have to call this manually):

```json
// package.json
"scripts": {
  "build": "node esbuild.config.js",
  "build:css": "tailwindcss --postcss -i ./app/assets/stylesheets/application.tailwind.css -o ./app/assets/builds/application.css"
},
```

Rails ships with `bin/dev` script that calls `Procfile.dev`. To change behaviour of bin/dev, edit the procfile:

```
<!-- Procfile.dev -->
web: bin/rails server -p 3000
js: yarn build --rebuild
css: yarn build:css --watch
```

### Install CableReady, StimulusReflex, and Mrujs

...

## Chapter 2

### Users and accounts with Devise

Temporarily using fork of devise at 'DavidColby/devise' because Devise and Turbo-enabled Rails 7 not yet working together.

test1@example.com/123456

Add devise gem, with customizations to create `Account` model whenever a new `User` is registered.

```
bin/rails generate devise:views
bin/rails g devise User account:references first_name:string last_name:string
bin/rails g devise:controllers users -c=registrations
bin/rails g devise:controllers users -c=sessions
```

### Tailwind

Remove spaces between `hover` and `focus` and `:` fixes compilation errors.

### Stimulus

[Reference](https://stimulus.hotwired.dev/handbook/introduction)

[Regular Rails Flash Messages](https://www.rubyguides.com/2019/11/rails-flash-messages/)

> Stimulus is a JavaScript framework with modest ambitions. Unlike other front-end frameworks, Stimulus is designed to enhance static or server-rendered HTML—the “HTML you already have”—by connecting JavaScript objects to elements on the page using simple annotations.

Use Stimulus to display toast messages in the Rails `flash` hash.

To generate a stimulus controller:

```
rails g stimuls alert
```

Creates file in `app/javascript/controllers` and runs `stimulus:manifest:update` to register the new controller in `app/javascript/controllers/index.js`.

Stimulus has [lifecycle callbacks](https://stimulus.hotwired.dev/reference/lifecycle-callbacks). We'll use:
* `initialize` Called when associated element first enters the DOM
* `connect` Caalled every time associated element enters the DOM

See `app/javascript/controllers/alert_controller.js`. This gets connected to DOM in `app/views/shared/_flash.html.erb`

`<div data-controller="alert"...` tells Stimulus to instantiate a new instance of `AlertController` each time this HTML enters DOM.

`<button data-action="alert#close" ...` the [action](https://stimulus.hotwired.dev/reference/actions) attribute is how we trigger Stimulus methods based on user input. We can attach data-action attributes to any DOM element to listen for user interaction with the element as long as the element has a parent data-controller.

By default, Stimulus listens for `click` event for buttons. If wanted to listen for some other event such as `mouseup`:

```html
<button data-action="mouseup->alert#close">...</button>
```

Stimulus reference for [default events](https://stimulus.hotwired.dev/reference/actions#event-shorthand).

To get the flash partial `app/views/shared/_flash.html.erb` to render, update application layout `app/views/layouts/application.html.erb`:

```erb
<body>
  <div class="flex flex-col h-screen justify-between px-4 md:px-0">
    <main class="mb-auto w-full">
      <div class="mx-auto max-w-7xl">
        <%= yield %>
      </div>
    </main>
  </div>
  <div id="flash-container">
    <% flash.each do |key, value| %>
      <%= render "shared/flash", level: key, content: value %>
    <% end %>
  </div>
</body>
```

## Chapter 3: Job Postings

Standard Rails + [CableReady](https://cableready.stimulusreflex.com/) + a little Turbo Steams and Turbo Frames

> CableReady is a Ruby gem that lets you create great real-time user experiences by triggering client-side DOM changes, events and notifications over [ActionCable](https://guides.rubyonrails.org/action_cable_overview.html) web sockets. These commands are called operations.

A user of our ATS can create job postings that (later) applicants can apply to.

Use `scaffold` generator to create Job model, controller, and views:

```
rails g scaffold Job title:string status:string:index job_type:string:index location:string account:references
```

Use [ActionText](https://guides.rubyonrails.org/action_text_overview.html) to store job description rather than having longtext description column on jobs table directly.

```
rails action_text:install
bundle install
rails db:migrate
```

### Creating jobs in a slideover

Up until now, the jobs routes are all standard Rails. i.e. clicking on the new job link takes the user to a new page to fill out the job posting form. After they submit the form they are redirected to the job posting.

Goal: Open job form in a slideover drawer instead of navigating to a new page. When form submitted, newly created job should be added to the existing list of jobs and the slide over drawer should close.

Create new stimulus controller:

```
rails g stimulus slideover
```

Unlike with alert controller (when we used Stimulus in Chapter 2), this time using `targets`:

```javascript
// app/javascript/controllers/slideover_controller.js
export default class extends Controller {
  // https://stimulus.hotwired.dev/reference/targets
  // target can be referenced in controller with `this.slideoverTarget`
  // Targets are DOM elements that we set when we connect a controller to the DOM.
  // When working with Stimulus, targets are used to obtain a reference to a specific DOM element.
  static targets = [ "slideover" ]
  ...
}
```

The corresponding partial `app/views/shared/_slideover.html.erb` has:

```erb
<div data-slideover-target="slideover">
  <div>
    <h3 id="slideover-header"></h3>
    <button data-action="slideover#close" aria-label="Close slideover">
      <%= inline_svg_tag 'close.svg', class: "h-7 w-7 text-white" %>
    </button>
  </div>
  <div>
    <div id="slideover-content"></div>
  </div>
</div>
```

**Notes**

* `data-slideover-target="slideover"` connects the dom element that has this data attribute to the slideover controller.
* `data-action="slideover#close` on the button element. This means when the button is clicked, the `close` function in the slideover controller will be invoked.
* div with id of `slideover-content` is intentionally left empty. This "component" will be re-used throughout app with different content loaded each time. Same goes for header iwht id of `slideover-header`.

To ensure the slideover component gets rendered, add it to main application layout:

Note we had to add `data-controller="slideover"` to the body element! Is this ok because it's a component that applies to the app globally?

```erb
<!-- app/views/layouts/application.html.erb -->
<body data-controller="slideover">
  <div class="flex flex-col h-screen justify-between px-4 md:px-0">
    <%= render "nav/top_nav" %>
    <main class="mb-auto w-full overflow-auto">
      <div class="mx-auto max-w-7xl md:px-6 lg:px-8 py-8">
        <%= yield %>
      </div>
    </main>
    <%= render "shared/footer" %>
    <div id="flash-container">
      <% flash.each do |key, value| %>
        <%= render "shared/flash", level: key, content: value %>
      <% end %>
    </div>
  </div>
  <%= render "shared/slideover" %>
</body>
```

Next up we want the slideover to open when user clicks to create a new job. Earlier when we scaffolded the Jobs model, Rails generated `app/views/jobs/index.html.erb` with a create link like this:

```erb
<!-- app/views/jobs/index.html.erb -->
<%= link_to "Post a new job", new_job_path %>
```

Where `new_job_path` is defined at `/jobs/new`, handled by `app/controllers/jobs_controller.rb#new`.

Now let's change this link to add some data attributes:

```erb
<!-- app/views/jobs/index.html.erb -->
<%= link_to "Post a new job",
new_job_path,
class: "btn-primary-outline",
data: {
  action: "click->slideover#open",
  remote: true
} %>
```

Looking at the "Post a new job" link in browser, it generated this DOM:

```htm
<a class="btn-primary-outline" data-action="click->slideover#open" data-remote="true" href="/jobs/new" data-turbo="false">Post a new job</a>
```

**Notes**

* `data-action` tells Stimulus to fire `slideover#open` when the link is clicked.
* `data-remote` indicates that the link should be handled by [Mrujs' CableCar plugin](https://mrujs.com/how-tos/integrate-cablecar#examples). This means the link will expect CableCar JSON returned.
* Clicking the link will still invoke an http GET request to `new_job_path` on the Rails server. We're going to modify the new method in jobs controller to return the CableCar JSON expected by Mrujs.

Need to update `new` method in jobs controller to respond with expected JSON for CableCar.

Here is original `new` method generated by Rails scaffold, which by default, renders the `app/views/jobs/new.html.erb` view:

```ruby
# app/controllers/jobs_controller.rb
class JobsController < ApplicationController
  # ...

  # GET /jobs/new
  def new
    @job = Job.new
  end
  # ...
end
```

Here is the updated `new` method to work with CableCar:

```ruby
def new
  # render the jobs form partial (app/views/jobs/_form.html.erb) to a string
  html = render_to_string(partial: 'form', locals: { job: Job.new })

  # render cable_car operations which are sent back to the browser as a JSON payload that Mrujs handles.
  render operations: cable_car
    .inner_html('#slideover-content', html: html)
    .text_content('#slideover-header', text: 'Post a new job')
end
```

**Notes**

* Using CableReady through the CableCar plugin does not require WebSockets or ActionCable.
* Using CableCar and Mrujs keeps users in the normal request/response cycle, without involving WebSockets.
* User makes a request in their browser -> Rails responds to that request with JSON payload containing CableReady operations.
* Mrujs receives that response in the browser, then calls `cableReady.perform` which applies the operations sent from the server, no WebSockets required.
* CableReady has many operations but we're going to be using it to add, remove, and update DOM elements, as well as update data attributes in response to user actions.

Just for fun, here' is ChatGPT's explanation of the controller code:

![cable car ops chatgpt](doc-images/cable-car-ops-chatgpt.png "cable car ops chatgpt")

In order to render `cable_car` operations from a Rails controller, need to include `CableReady::Broadcaster` in controller. But we're going to be doing this throughout app, so put it in main application controller:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include CableReady::Broadcaster
end
```

This makes CableReady broadcast operations from server to browser, and browser processes these operations.

Left at "we can pause here to test that the slideover works as expected"

TODO: Paste in request as shown in Rails server and HTTP JSON response from browser dev tools.

Try the slideover from `http://localhost:3000/jobs` and click Post a job:

Browser submits GET request to Rails server. Notice `accept` header of `vnd.cable-ready.json`:

```
curl 'http://localhost:3000/jobs/new' \
-H 'Accept-Language: en-US,en;q=0.9' \
-H 'Connection: keep-alive' \
-H 'Cookie: __profilin=p%3Dt; _news_session=dma9Qz...' \
-H 'If-None-Match: W/"e70b236c3da9e7b86af8c229f9926147"' \
-H 'Referer: http://localhost:3000/jobs' \
-H 'Sec-Fetch-Dest: empty' \
-H 'Sec-Fetch-Mode: cors' \
-H 'Sec-Fetch-Site: same-origin' \
-H 'User-Agent: Mozilla...' \
-H 'accept: application/vnd.cable-ready.json, */*' \
-H 'x-requested-with: XmlHttpRequest' \
--compressed
```

Here's what it looks like when received on Rails server:

```
Started GET "/jobs/new" for ::1 at 2022-12-23 06:49:27 -0500
Processing by JobsController#new as CABLE_READY
User Load (9.0ms)  SELECT "users".* FROM "users" WHERE "users"."id" = ? ORDER BY "users"."id" ASC LIMIT ?  [["id", 1], ["LIMIT", 1]]
Rendered jobs/_form.html.erb (Duration: 91.7ms | Allocations: 6660)
Completed 200 OK in 225ms (Views: 1.9ms | ActiveRecord: 9.0ms | Allocations: 9432)
```

Here is the response received by browser from `http://localhost:3000/jobs/new`. Notice the content type of `vnd.cable-ready.json`

```
HTTP/1.1 200 OK
X-Frame-Options: SAMEORIGIN
X-XSS-Protection: 0
X-Content-Type-Options: nosniff
X-Download-Options: noopen
X-Permitted-Cross-Domain-Policies: none
Referrer-Policy: strict-origin-when-cross-origin
Content-Type: application/vnd.cable-ready.json; charset=utf-8
Vary: Accept
ETag: W/"e401f9d2a671c74860b85d83faa029eb"
Cache-Control: max-age=0, private, must-revalidate
Set-Cookie: _hotwired_ats_session=pGXVC9...; path=/; HttpOnly; SameSite=Lax
X-Request-Id: ebc73e4c-9d90-4b54-ab26-ec9864bed4e0
X-Runtime: 0.330878
Server-Timing: start_processing.action_controller;dur=0.56, sql.active_record;dur=37.23, instantiation.active_record;dur=1.02, render_partial.action_view;dur=91.96, process_action.action_controller;dur=225.21
Transfer-Encoding: chunked


[
    {
        "html": "<form action=\"/jobs\" accept-charset=\"UTF-8\" method=\"post\"><input type=\"hidden\" name=\"authenticity_token\" value=\"jaUH2AtxVN0dPnhRthfE9moJXYDEWLxBGqjF9hmMHB_MVDFCT7NbLnXrnarlRTapGO5_cx_7zRBj9qaTTi9EoQ\" autocomplete=\"off\" />\n\n  <div>\n    <label style=\"display: block\" for=\"job_title\">Title</label>\n    <input type=\"text\" name=\"job[title]\" id=\"job_title\" />\n  </div>\n\n  <div>\n    <label style=\"display: block\" for=\"job_status\">Status</label>\n    <input type=\"text\" value=\"open\" name=\"job[status]\" id=\"job_status\" />\n  </div>\n\n  <div>\n    <label style=\"display: block\" for=\"job_job_type\">Job type</label>\n    <input type=\"text\" value=\"full_time\" name=\"job[job_type]\" id=\"job_job_type\" />\n  </div>\n\n  <div>\n    <label style=\"display: block\" for=\"job_location\">Location</label>\n    <input type=\"text\" name=\"job[location]\" id=\"job_location\" />\n  </div>\n\n  <div>\n    <label style=\"display: block\" for=\"job_account_id\">Account</label>\n    <input type=\"text\" name=\"job[account_id]\" id=\"job_account_id\" />\n  </div>\n\n  <div>\n    <input type=\"submit\" name=\"commit\" value=\"Create Job\" data-disable-with=\"Create Job\" />\n  </div>\n</form>",
        "selector": "#slideover-content",
        "operation": "innerHtml"
    },
    {
        "text": "Post a new job",
        "selector": "#slideover-header",
        "operation": "textContent"
    }
]
```

Notice the response includes two operations: `innerHtml` and `textContent`. This is because of our code in jobs controller new method:

```ruby
render operations: cable_car
  .inner_html('#slideover-content', html: html)
  .text_content('#slideover-header', text: 'Post a new job')
```

So the `innerHtml` operation is used to set the inner html of `#slideover-content` with the rendered form partial.

And the `textContent` operation is used to set the text content of `#slideover-header` with text "Post a new job".

Let's make the form partial have human readable dropdown values for status and job type. Notice that job description is using the Trix editor for the rich text area:

```erb
<%= form_with(model: job, html: { class: "space-y-6" }) do |form| %>
  <% if job.errors.any? %>
    <div id="error_explanation">
      <h2><%= pluralize(job.errors.count, "error") %> prohibited this job from being saved:</h2>

      <ul>
        <% job.errors.each do |error| %>
          <li><%= error.full_message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="form-group">
    <%= form.label :title %>
    <div class="mt-1">
      <%= form.text_field :title %>
    </div>
  </div>

  <div class="form-group">
    <%= form.rich_text_area :description %>
  </div>

  <div class="form-group">
    <%= form.label :status %>
    <%= form.select :status, options_for_select(Job.statuses.map{|key, _value| [key.humanize, key]}, job.status), {}, { class: "mt-1" } %>
  </div>

  <div class="form-group">
    <%= form.label :job_type %>
    <%= form.select :job_type, options_for_select(Job.job_types.map{|key, _value| [key.humanize, key]}, job.job_type), {}, { class: "mt-1" } %>
  </div>

  <div class="form-group">
    <%= form.label :location %>
    <div class="mt-1">
      <%= form.text_field :location %>
    </div>
  </div>

  <%= form.submit 'Submit', class: 'btn-primary float-right' %>
<% end %>
```

To make the trix editor look better, modified `app/assets/stylesheets/actiontext.css` as follows:

```css
@import "trix/dist/trix";

.trix-button--icon-increase-nesting-level,
.trix-button--icon-decrease-nesting-level,
.trix-button--icon-strike,
.trix-button--icon-code,
.trix-button-group.trix-button-group--file-tools {
  display: none;
}

trix-editor.trix-content {
  @apply appearance-none w-full max-w-prose bg-white text-gray-700 border-gray-200 rounded-sm text-lg focus:ring-1 focus:ring-blue-300 focus:border-blue-300;
  min-height: 400px;
}
```

Currently when the Job form is submitted from open slideover, user redirected to new page `http://localhost:3000/jobs/2`. This is because clicking Submit button from `app/views/jobs/_form.html.erb` submits http POST to `/jobs` endpoint which is handled by `JobsController#create` which redirects to the newly created job show page if the save is successful:

```ruby
# app/controllers/jobs_controller.rb
def create
  @job = Job.new(job_params)
  @job.account = current_user.account

  respond_to do |format|
    if @job.save
      format.html { redirect_to job_url(@job), notice: "Job was successfully created." }
      format.json { render :show, status: :created, location: @job }
    else
      format.html { render :new, status: :unprocessable_entity }
      format.json { render json: @job.errors, status: :unprocessable_entity }
    end
  end
end
```

### Creating job postings

Let's update things so the user remains on the jobs index page `http://localhost:3000/jobs` that shows all jobs, but with an updated listing so the newly created job gets added to the list, *without* a full page refresh.

Solution will be to use CableReady to close the slideover, and insert new job into existing list of jobs.

Update `create` method in jobs controller to render CableReady operations:

```ruby
def create
  @job = Job.new(job_params)
  @job.account = current_user.account
  if @job.save
    html = render_to_string(partial: 'job', locals: { job: @job })
    render operations: cable_car
      .prepend('#jobs', html: html)
      .dispatch_event(name: 'submit:success')
  else
    html = render_to_string(partial: 'form', locals: { job: @job })
    render operations: cable_car
      .inner_html('#job-form', html: html), status: :unprocessable_entity
  end
end
```

For the success case:
* Render the `app/views/jobs/_job.html.erb` partial and [prepend](https://developer.mozilla.org/en-US/docs/Web/API/Element/prepend) it to DOM element `#jobs` (where is this defined?).
* Also [dispatch a custom DOM event](https://cableready.stimulusreflex.com/reference/operations/event-dispatch#dispatch_event) `submit:success` which will be used by the slideover controller to close itself.

Recall the `open` function in the slideover controller (stimulus), listens for this event to close itself:

```javascript
// app/javascript/controllers/slideover_controller.js
open() {
  this.visible = true
  document.body.insertAdjacentHTML('beforeend', this.backgroundHtml)
  this.background = document.querySelector(`#slideover-background`)
  this.toggleSlideover()

  // This event listener, submit:success, is how we close the drawer after a successful form submission.
  document.addEventListener("submit:success", () => {
    this.close()
  }, { once: true })
}
```

Note that it's also possible to do this (server broadcasts event to be handled by client side javascript controller) with TurboStreams but its easier and more flexible to do with CableReady.

For failure case, we re-render the job form partial `app/views/jobs/_form.html.erb` with the job instance, which will now contain model errors, which will be displayed in forms. Then replace inner html of the `#job-form` DOM element with this partial, also sending http status `:unprocessable_entity`.

Also in order to process the rich text job field `description`, add it to allowed params in jobs controller:

```ruby
# app/controllers/jobs_controller.rb
def job_params
  params.require(:job).permit(:title, :status, :job_type, :location, :account_id, :description)
end
```

Update job form partial to add `data-remote` attribute (as we did earlier on new job link), and also specify `job-form` as the ID of the form element. This DOM id is needed for the job create error case to render: `.inner_html('#job-form', html: html), status: :unprocessable_entity`:

```erb
<!-- app/views/jobs/_form.html.erb -->
<%= form_with(
  model: job,
  id: 'job-form',
  html: { class: "space-y-6" },
  data: { remote: true }
) do |form| %>
<!-- ... rest of form ... -->
```

Add `#jobs` DOM id to the job container div in jobs index view. This is so the success case will be able to prepend a job job to the list `.prepend('#jobs', html: html)`:

```erb
<div class="divide-y divide-gray-200" id="jobs">
  <%= render @jobs %>
</div>
```

### Slideover edit links

Update edit link in job partial with data-action to tell it to open the slideover, and remote attribute so it will accept CableReady JSON:

```ruby
# app/views/jobs/_job.html.erb
<%= link_to job.title,
edit_job_path(job),
class: "text-lg text-blue-600 hover:text-blue-700",
data: {
  action: "click->slideover#open",
  remote: true
} %>
```

The `edit_job_path` is standard Rails, which will invoke the `edit` method in the jobs controller. Currently the edit method has default Rails behaviour which is to render the view `app/views/jobs/edit.html.erb` in a new page:

```ruby
# app/controllers/jobs_controller.rb
# GET /jobs/1/edit
def edit
end
```

Update `edit` method so that it instead uses CableReady operations to update slideover content with rendered job form partial, this time with a job instance so that the form will be pre-populated with that job's details:

```ruby
# app/controllers/jobs_controller.rb
def edit
  html = render_to_string(partial: 'form', locals: { job: @job })
  render operations: cable_car
    .inner_html('#slideover-content', html: html)
    .text_content('#slideover-header', text: 'Update job')
end
```

Note that `@job` instance var is populated in controller's `before_action`.

Also need to update the `update` method in controller to [replace](https://cableready.stimulusreflex.com/reference/operations/dom-mutations#replace) the current job in the DOM. Note use of `dom_id(@job)` to select the correct DOM element to be replaced:

```ruby
# app/controllers/jobs_controller.rb
def update
  if @job.update(job_params)
    html = render_to_string(partial: 'job', locals: { job: @job })
    render operations: cable_car
      .replace(dom_id(@job), html: html)
      .dispatch_event(name: 'submit:success')
  else
    html = render_to_string(partial: 'form', locals: { job: @job })
    render operations: cable_car
      .inner_html('#job-form', html: html), status: :unprocessable_entity
  end
end
```

### Deleting jobs

Update delete link in job partial  to add `remote` attribute to make it accept/receive CableReady JSON. No need for `data-action` because we don't need to open/close slideover drawer for delete action:

```erb
<!-- app/views/jobs/_job.html.erb -->
<%= button_to "Delete job",
job_path(job),
method: :delete,
class: "btn border border-red-200 hover:bg-red-100 text-sm text-red-700",
remote: true,
data: {
  confirm: "Are you sure?"
} %>
```

Calling clicking button to `job_path` with `method: :delete` invokes `destroy` method in jobs controller. Update this method to render CableReady [remove](https://cableready.stimulusreflex.com/reference/operations/dom-mutations#remove) operation to remove the DOM element identified by `dom_id(@job)`:

```ruby
# app/controllers/jobs_controller.rb
def destroy
  @job.destroy
  render operations: cable_car.remove(selector: dom_id(@job))
end
```

### Adding jobs with Turbo Streams

So far, have used Stimulus/StimulusReflex, CableReady and Mrujs to open/close slideover, populate it with content and process form submissions.

Another way to achieve this is with Stimulus, Turbo Streams, and Turbo Frames. Do this in a separate branch...

Author says CableReady more flexible for complex situations.

## My Questions and Comments

1. Original `forms.css` from Chapter 1 has some syntax errors - space between hover and focus and `:` was causing Tailwind to not compile and breaking site styles. Solution is to remove extra spaces, so `hover:...` instead of `hover :...`
2. Having lots of utility classes in erb templates makes it difficult to also notice all the `data...` attributes that are used for reactivity with Stimulus, CableCar etc. This could make it challenging for a new developer joining a project to quickly scan the templates to determine which portions are controlled by what Stimulus controllers.
3. The flash partial `app/views/shared/_flash.html.erb` is connected to the Stimulus alert controller `app/javascript/controllers/alert_controller.js` via `<div data-controller="alert"...` Is there a naming convention similar to Rails controllers and views? Eg: Should the controller be named `flash_controller` to match the template name?
5. Is it considered good practice to make a Stimulus controller globally available via `<body data-controller="slideover">` in `app/views/layouts/application.html.erb`?
   1. Could this cause confusion when any template or partial anywhere in the app could reference functions in the slideover controller but any developer that didn't add the global might not know where this is defined?
   2. Could this cause the slideover controller to become a "dumping ground" for any other js functions that need to get executed anywhere in the app?
6. The slideover Stimuls controller `app/javascript/controllers/slideover_controller.js` has a function `backgroundHTML` that returns some markup. Is this considered good practice to mix logic and markup in a Stimulus controller? i.e. what should be the concerns of a Stimuls controller?
7. Seeing error in Rails server output `ActionController::RoutingError (No route matches [GET] "/assets/application.js-2f5ffb65c42075102a7a135fbe646944950943ded66c4ae0aeebbf43ff329d26.map")`. Missing source map?
8. Seeing warning in build/dev output when added animation css `No utilities were generated there is likely a problem with the `content` key in the tailwind config. For more information see the documentation: https://tailwindcss.com/docs/content-configuration`
9. When rendering a CableCar JSON response from a Rails controller such as `.inner_html('#slideover-content', html: html)`, what's the scope of the DOM that will be searched for finding the given selector? i.e. will it match the first `#slideover-content` found *anywhere* in the DOM? Or only the element that is located within the partial `app/views/shared/_slideover.html.erb`? The CableReady doc for [inner_html](https://cableready.stimulusreflex.com/reference/operations/dom-mutations#inner_html) doesn't explain or even have a DOM selector.
   1. Maybe this is the answer from CableReady [usage](https://cableready.stimulusreflex.com/usage): "By default, the selector option provided to DOM-mutating operations expects a CSS selector that resolves to one single DOM element. If multiple elements are returned, only the first one is used."
   2. If it's not scoped to the partial, this could get tricky as the project grows, another developer working on a different feature may add a DOM element by chance that has the same name, and then the wrong element would get updated, breaking this feature.
10. How to debug/step through js in Stimulus controller?