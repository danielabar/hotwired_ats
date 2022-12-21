# README

Learning Rails with the Hotwire stack, CableReady, and StimulusReflex with [this book](https://book.hotwiringrails.com/chapters). Github [repo](https://github.com/DavidColby/hotwired_ats_code).

```
docker-compose up
bin/rails db:create
bin/dev
```

## References

TODO: Go back over Chapter 1 and list every part of tech stack and what it's used for.

* [StimulsReflex](https://docs.stimulusreflex.com/): extends capabilities of Rails and [Stimulus](https://stimulus.hotwired.dev/)
* [Mrujs](https://mrujs.com/)
  * [CableCar Plugin for Mrujs](https://mrujs.com/how-tos/integrate-cablecar) to make it easier to work with CableReady?
* [CableReady](https://cableready.stimulusreflex.com/)
  * [CableReady Operations](https://cableready.stimulusreflex.com/reference/operations)

## Chapter 1: Setup

Note project is using [Mrujs](https://mrujs.com/). Mrujs is intended as a direct replacement for `@rails/ujs`, which used to ship by default with Rails 6 but has since been deprecated.

## Chapter 2

### Devise

test1@example.com/123456

Add devise gem, with customizations to create `Account` model whenever a new `User` is registered.

```
bin/rails generate devise:views
bin/rails g devise User account:references first_name:string last_name:string
bin/rails g devise:controllers users -c=registrations
bin/rails g devise:controllers users -c=sessions
```

### Tailwind

Added a bunch of Tailwind stuff that isn't working, despite downgrading to same version as author's in `package.json`.

Had to comment out: `app/assets/stylesheets/forms.css`

Actually: Remove spaces between `hover` and `focus` and `:` fixes compilation errors.

### Stimulus

[Reference](https://stimulus.hotwired.dev/handbook/introduction)

[Regular Rails Flash Messages](https://www.rubyguides.com/2019/11/rails-flash-messages/)

> Stimulus is a JavaScript framework with modest ambitions. Unlike other front-end frameworks, Stimulus is designed to enhance static or server-rendered HTML—the “HTML you already have”—by connecting JavaScript objects to elements on the page using simple annotations.

Use Stimulus to display toast messages in the Rails `flash` hash.

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

**Notes**

* `data-action` tells Stimulus to fire `slideover#open` when the link is clicked.
* `data-remote` indicates that the link should be handled by [Mrujs' CableCar plugin](https://mrujs.com/how-tos/integrate-cablecar#examples). This means the link will expect CableCar JSON returned.

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

## My Questions and Comments

1. Original `forms.css` from Chapter 1 has some syntax errors - space between hover and focus and `:` was causing Tailwind to not compile and breaking site styles. Solution is to remove extra spaces, so `hover:...` instead of `hover :...`
2. Having lots of utility classes in erb templates makes it difficult to also notice all the `data...` attributes that are used for reactivity with Stimulus, CableCar etc. This could make it challenging for a new developer joining a project to quickly scan the templates to determine which portions are controlled by what Stimulus controllers.
3. The flash partial `app/views/shared/_flash.html.erb` is connected to the Stimulus alert controller `app/javascript/controllers/alert_controller.js` via `<div data-controller="alert"...` Is there a naming convention similar to Rails controllers and views? Eg: Should the controller be named `flash_controller` to match the template name?
5. Is it considered good practice to make a Stimulus controller globally available via `<body data-controller="slideover">` in `app/views/layouts/application.html.erb`?
   1. Could this cause confusion when any template or partial anywhere in the app could reference functions in the slideover controller but any developer that didn't add the global might not know where this is defined?
   2. Could this cause the slideover controller to become a "dumping ground" for any other js functions that need to get executed anywhere in the app?
6. The slideover Stimuls controller `app/javascript/controllers/slideover_controller.js` has a function `backgroundHTML` that returns some markup. Is this considered good practice to mix logic and markup in a Stimulus controller? i.e. what should be the concerns of a Stimuls controller?
7. Seeing error in Rails server output `ActionController::RoutingError (No route matches [GET] "/assets/application.js-2f5ffb65c42075102a7a135fbe646944950943ded66c4ae0aeebbf43ff329d26.map"):`