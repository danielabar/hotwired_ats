<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Chapter 6: Viewing and contacting applicants](#chapter-6-viewing-and-contacting-applicants)
  - [Building the applicant show page](#building-the-applicant-show-page)
  - [Displaying resumes](#displaying-resumes)
  - [Build email resource](#build-email-resource)
  - [Send emails to applicants](#send-emails-to-applicants)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Chapter 6: Viewing and contacting applicants

Will be building applicant show page to display applicant details, including resume.

Will add ability to email applicants and receive replies using ActionMailbox.

### Building the applicant show page

According to author of book, after the applicant listing was wrapped in Turbo Frame, clicking on links to view applicants stopped working because navigation within Turbo Frame is scoped within that frame.

But for me, clicking Applicant name within the card partial `app/views/applicants/_card.html.erb` does work, doing a navigation to new page, for example: http://localhost:3000/applicants/243

In Chapter 5, used `data-turbo-frame` attribute to specify which turbo frame form response should get loaded into:

```erb
<!-- app/views/applicants/_filter_form.html.erb -->
<%= form_with url: applicants_path,
              method: :get,
              data: {
                controller: "form",
                form_target: "form",
                turbo_frame: "applicants",
                turbo_action: "advance"
              } do |form| %>
```

Can also use `data-turbo-frame` attribute to navigate from within a frame into a full page navigation by specifying `_top` value:

```erb
<!-- app/views/applicants/_card.html.erb -->
<h4 class="text-gray-900">
  <%= link_to(
    applicant.name,
    applicant,
    data: {
      turbo_frame: "_top"
    }
  ) %>
</h4>
```

Update applicant show view:

```erb
<div class="flex items-baseline justify-between mb-6 text-gray-700">
  <h2 class="mt-6 text-3xl font-extrabold">
    <%= @applicant.name %>
  </h2>
  <%= link_to "Send email", "#", class: "btn-primary-outline", data: { action: "click->slideover#open", remote: true } %>
</div>
<div class="shadow p-4 text-gray-700">
  <div class="flex justify-between mb-6">
    <div class="space-y-2">
      <h3 class="text-xl font-bold">Applicant info</h3>
      <p><%= mail_to @applicant.email %></p>
      <p><%= phone_to @applicant.phone %></p>
    </div>
    <div class="space-y-2">
      <h3 class="text-xl font-bold">Application details</h3>
      <p>Applied for <%= @applicant.job.title %></p>
      <p>Applied on <%= l(@applicant.created_at.to_date, format: :long) %></p>
    </div>
    <div class="space-y-2">
		<!-- Applicant actions go here -->
    </div>
  </div>
  <!-- Resume goes here -->
</div>
```

**Notes**

* opening "Send Email" slideover just opens the drawer empty for now, will fill it in later

### Displaying resumes

Resume is saved as pdf file and ActiveStorage. Could be large in case there's embedded images. Don't want user to wait for pdf to download before the Applicant show page renders.

Will use Turbo Frames to lazy load the pdf content. i.e. defer request for resume until the rest of the Applicant show page is loaded and frame is visible.

Start with Resumes controller:

```
rails g controller Resumes show
```

Update router to add a GET request for resumes, as part of applicants:

```ruby
# config/routes.rb
resources :applicants do
  patch :change_stage, on: :member
  get :resume, action: :show, controller: 'resumes'
end
```

Applicant routes now look like this - note that there is no resume `id`, because each applicant just has a single resume pdf file:

```
Prefix Verb   URI Pattern                                                                                       Controller#Action
change_stage_applicant PATCH  /applicants/:id/change_stage(.:format)                                                            applicants#change_stage
      applicant_resume GET    /applicants/:applicant_id/resume(.:format)                                                        resumes#show
            applicants GET    /applicants(.:format)                                                                             applicants#index
                       POST   /applicants(.:format)                                                                             applicants#create
         new_applicant GET    /applicants/new(.:format)                                                                         applicants#new
        edit_applicant GET    /applicants/:id/edit(.:format)                                                                    applicants#edit
             applicant GET    /applicants/:id(.:format)                                                                         applicants#show
                       PATCH  /applicants/:id(.:format)                                                                         applicants#update
                       PUT    /applicants/:id(.:format)                                                                         applicants#update
                       DELETE /applicants/:id(.:format)                                                                         applicants#destroy
```

Add `show` action in resumes controller - note again no resume id, just applicant id, find the applicant, then return their associated ActiveStorage resume:

```ruby
# app/controllers/resumes_controller.rb
class ResumesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_applicant, only: %i[show]

  def show
    @resume = @applicant.resume
  end

  private

  def set_applicant
    @applicant = Applicant.find(params[:applicant_id])
  end
end
```

Resume show view:

```erb
<!-- app/views/resumes/show.html.erb -->
<%= turbo_frame_tag "resume" do %>
  <div class="w-full">
    <iframe src="<%= url_for(@resume) %>" width="100%" height="1000"></iframe>
  </div>
<% end %>
```

**Notes**

* resume show view is wrapped in `turbo_frame_tag`
* applicant show page will have a matching empty Turbo Frame that the resume show view will be responsible for replacing
* using [url_for](https://edgeguides.rubyonrails.org/active_storage_overview.html#redirect-mode) from ActiveStorage to build `src` for iframe
* value of `url_for(@resume)` returns something like: `/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBZ3NCIiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--defc26cac0e26bb770674c52819c957da166be14/temp-example-1.pdf`

Update applicants show page to render empty TurboFrame for `resume`:

```erb
<% if @applicant.resume.attached? %>
  <%= turbo_frame_tag "resume", src: applicant_resume_path(@applicant), loading: "lazy" do %>
    <div class="w-full bg-gray-100 rounded flex justify-center items-center h-[1000px]">
      Loading...
    </div>
  <% end %>
<% end %>
```

**Notes**

* `src` attribute on turbo_frame_tag tells Turbo to load content from a [specified url](https://turbo.hotwired.dev/reference/frames#eager-loaded-frame)
* `applicant_resume_path(@applicant)` returns something like: `http://localhost:3000/applicants/269/resume`
* `loading: "lazy"` [attribute](https://turbo.hotwired.dev/reference/frames#lazy-loaded-frame) tells Turbo to wait until frame is visible before loading the content

Try refresh applicant show page for applicant with a resume -> page initially shows "Loading..." placeholder content inside resume turbo frame. Then request sent to `/applicants:id/resume` and content of resume frame replaced with applicant's pdf resume file, embedded in PDF viewer.

Rails server output first has request to: `Started GET "/applicants/269"`, and after that view renders, Rails server receives second request to `Started GET "/applicants/269/resume"`.

After resume loaded, applicant show page for a particular applicant such as http://localhost:3000/applicants/269 looks like this:

![applicant show with resume](../doc-images/applicant-show-with-resume.png "applicant show with resume")

**Notes**

* With eager or lazy loaded Turbo Frame, additional attributes that you want to set on frame such as `src` or `lazy` *must* be set when frame is initially rendered. In our example, `src` and `lazy` set on version of frame rendered by `applicant#show` view.
* When frame enters DOM, Turbo processes the attributes to trigger a request to the url specified by `src`, then replaces the inner HTML of the Turbo Frame with response from server (`resumes#show` in our example).
* Turbo Frame requests only update inner HTML of Turbo Frame
* Parent `turbo-frame` element is almost never modified after first time render

### Build email resource

Will build email system for outbound emails to applicants, replies from applicants, and replying to replies via email threads.

Store all emails (inbound/outbound) in `emails` table:

```
bin/rails g model Email applicant:references user:references subject:text sent_at:datetime
bin/rails db:migrate
```

Add `body` field as rich text and validation of `subject` field:

```ruby
# app/models/email.rb
class Email < ApplicationRecord
  has_rich_text :body

  belongs_to :applicant
  belongs_to :user

  validates_presence_of :subject
end
```

Update User and Applicant models to specify has_many emails:

```ruby
# This line goes in both the User model and the Applicant model
has_many :emails, dependent: :destroy
```

Generate emails controller:

```
rails g controller Emails
touch app/views/emails/_form.html.erb
```

Update router - notice the emails routes are nested under applicants

```ruby
resources :applicants do
  patch :change_stage, on: :member
  resources :emails, only: %i[index new create show]
  get :resume, action: :show, controller: 'resumes'
end
```

Applicant routes now are:

```
Prefix Verb   URI Pattern                                                                                       Controller#Action
change_stage_applicant PATCH  /applicants/:id/change_stage(.:format)                                                            applicants#change_stage
      applicant_emails GET    /applicants/:applicant_id/emails(.:format)                                                        emails#index
                       POST   /applicants/:applicant_id/emails(.:format)                                                        emails#create
   new_applicant_email GET    /applicants/:applicant_id/emails/new(.:format)                                                    emails#new
       applicant_email GET    /applicants/:applicant_id/emails/:id(.:format)                                                    emails#show
      applicant_resume GET    /applicants/:applicant_id/resume(.:format)                                                        resumes#show
            applicants GET    /applicants(.:format)                                                                             applicants#index
                       POST   /applicants(.:format)                                                                             applicants#create
         new_applicant GET    /applicants/new(.:format)                                                                         applicants#new
        edit_applicant GET    /applicants/:id/edit(.:format)                                                                    applicants#edit
             applicant GET    /applicants/:id(.:format)                                                                         applicants#show
                       PATCH  /applicants/:id(.:format)                                                                         applicants#update
                       PUT    /applicants/:id(.:format)                                                                         applicants#update
                       DELETE /applicants/:id(.:format)                                                                         applicants#destroy
```

Here is the email form partial:

```erb
<!-- app/views/emails/_form.html.erb -->
<%= form_with(model: [applicant, email], id: 'email-form', html: { class: "space-y-6" }, data: { remote: true }) do |form| %>
  <% if email.errors.any? %>
    <div id="error_explanation">
      <h2><%= pluralize(email.errors.count, "error") %> prohibited this email from being saved:</h2>

      <ul>
        <% email.errors.each do |error| %>
          <li><%= error.full_message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="form-group">
    <%= form.label :subject %>
    <div class="mt-1">
      <%= form.text_field :subject %>
    </div>
  </div>

  <div class="form-group">
    <%= form.rich_text_area :body %>
  </div>

  <%= form.submit 'Send email', class: 'btn-primary float-right' %>
<% end %>
```

**Notes**

* Mrujs + CableCar will be handling form submission that's why data `remote: true` is set on form element.
* Using Trix editor via `form.rich_text_area` to allow some formatting of email `body`.

Update emails controller `new`, `create` actions - similar CableCar logic used for Jobs, Applicants:

```ruby
# app/controllers/emails_controller.rb
class EmailsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_applicant

  def new
    @email = Email.new
    html = render_to_string(partial: 'form', locals: { email: @email, applicant: @applicant })
    render operations: cable_car
      .inner_html('#slideover-content', html: html)
      .text_content('#slideover-header', text: "Email #{@applicant.name}")
  end

  def create
    @email = Email.new(email_params)

    @email.applicant = @applicant
    @email.user = current_user
    if @email.save
      html = render_to_string(partial: 'shared/flash', locals: { level: :success, content: 'Email sent!' })
      render operations: cable_car
        .inner_html('#flash-container', html: html)
        .dispatch_event(name: 'submit:success')
    else
      html = render_to_string(partial: 'form', locals: { applicant: @applicant, email: @email })
      render operations: cable_car
        .inner_html('#email-form', html: html), status: :unprocessable_entity
    end
  end

  private

  def set_applicant
    @applicant = Applicant.find(params[:applicant_id])
  end

  def email_params
    params.require(:email).permit(:subject, :body)
  end
end
```

**Notes**

* Difference from applicants and jobs controller is `create` action renders flash message confirming email sent. Use this technique when results of user's actions are not obvious to them.
* Email hasn't really been sent yet, only saved to `emails` table, will deal with this in next section.

Make the email form render in slideover by updating Send Email link on applicant show page:

```erb
<%= link_to "Send email",
new_applicant_email_path(@applicant),
class: "btn-primary-outline",
data: {
  action: "click->slideover#open",
  remote: true
} %>
```

### Send emails to applicants

Create a new [mailer](https://guides.rubyonrails.org/action_mailer_basics.html#create-the-mailer):

```
bin/rails g mailer Applicant contact
  create  app/mailers/applicant_mailer.rb
  invoke  erb
  create    app/views/applicant_mailer
  create    app/views/applicant_mailer/contact.text.erb
  create    app/views/applicant_mailer/contact.html.erb
```

**Notes**

* Mailer used to send outbound emails to applicants
* Email content will be from `rich_text :body` field from Email model

