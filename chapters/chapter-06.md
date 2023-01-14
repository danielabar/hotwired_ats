<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Chapter 6: Viewing and contacting applicants](#chapter-6-viewing-and-contacting-applicants)
  - [Building the applicant show page](#building-the-applicant-show-page)
  - [Displaying resumes](#displaying-resumes)
  - [Build email resource](#build-email-resource)
  - [Send emails to applicants](#send-emails-to-applicants)
  - [Receive and process inbound email](#receive-and-process-inbound-email)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Chapter 6: Viewing and contacting applicants

Will be building applicant show page to display applicant details, including resume.

Will add ability to email applicants and receive replies using ActionMailbox.

## Building the applicant show page

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

## Displaying resumes

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

## Build email resource

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

## Send emails to applicants

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

Update the generated applicant_mailer:

```ruby
# app/mailers/applicant_mailer.rb
class ApplicantMailer < ApplicationMailer
  def contact(email:)
    @email = email
    @applicant = @email.applicant
    @user = @email.user

    mail(
      to: @applicant.email,
      from: @user.email,
      subject: @email.subject
    )
  end
end
```

**Notes**

* `contact` method used to generate and send email
* `contact` method accepts an `email` argument, which will be `Email` model instance from database
* `mail` method constructs outgoing email

Fill in HTML and text content of `contact` mailer:

```erb
<!-- /Users/dbaron/projects/rails7/hotwired_ats/app/views/applicant_mailer/contact.html.erb -->
<%= @email.body %>
```

```erb
<!-- app/views/applicant_mailer/contact.text.erb -->
<%= @email.body.to_plain_text %>
```

To send email from app, use ActiveRecord [after_create_commit](https://api.rubyonrails.org/v7.0.4/classes/ActiveRecord/Transactions/ClassMethods.html#method-i-after_create_commit) callback in `Email` model. Also see [Transaction Callbacks](https://guides.rubyonrails.org/active_record_callbacks.html#transaction-callbacks) in Rails Guides.

```ruby
# app/models/email.rb
after_create_commit :send_email

def send_email
  ApplicantMailer.contact(email: self).deliver_later
end
```

**Notes**

* `after_create_commit` callback runs after new email record is added to the database
* `deliver_later` sends email as background task.
* We have not configured a persistent back end for ActiveJob so the default is an in-process thread pool, jobs in queue are dropped upon app restart. Fine for learning app but for production app, would need a real back end like Delayed Job, Resque, Sidekiq etc. See [Active Job Basics](https://guides.rubyonrails.org/active_job_basics.html).

Try this out by navigating to any applicant show view, eg: `http://localhost:3000/applicants/278`, click Send email, fill out the form and submit.

![aplicant send email](../doc-images/applicant-send-email.png "aplicant send email")

Rails server output shows a new record being saved in `emails` table with `body` being stored as rich text in `action_text_rich_texts` table.

Then ActiveJob is used to enqueue a `ActionMailer::MailDeliveryJob`. Then the job runs, rendering the email template and displaying result in console.

Don't know why it queries `active_storage_attachments` for record_id 233, this doesn't exist in database???
233 is id of `action_text_rich_texts` record containing email body. Maybe it's checking if there's also an attachment to send via email?

```
Started POST "/applicants/278/emails" for ::1 at 2023-01-14 07:45:51 -0500
Processing by EmailsController#create as CABLE_READY
  Parameters: {"authenticity_token"=>"[FILTERED]", "email"=>{"subject"=>"test", "body"=>"<div>some message</div>"}, "commit"=>"Send email", "applicant_id"=>"278"}
  User Load (5.0ms)  SELECT "users".* FROM "users" WHERE "users"."id" = $1 ORDER BY "users"."id" ASC LIMIT $2  [["id", 26], ["LIMIT", 1]]
  Applicant Load (1.8ms)  SELECT "applicants".* FROM "applicants" WHERE "applicants"."id" = $1 LIMIT $2  [["id", 278], ["LIMIT", 1]]
  ↳ app/controllers/emails_controller.rb:33:in `set_applicant'
  TRANSACTION (1.9ms)  BEGIN
  ↳ app/controllers/emails_controller.rb:18:in `create'
  Email Create (14.2ms)  INSERT INTO "emails" ("applicant_id", "user_id", "subject", "sent_at", "created_at", "updated_at") VALUES ($1, $2, $3, $4, $5, $6) RETURNING "id"  [["applicant_id", 278], ["user_id", 26], ["subject", "test"], ["sent_at", nil], ["created_at", "2023-01-14 12:45:51.949052"], ["updated_at", "2023-01-14 12:45:51.949052"]]
  ↳ app/controllers/emails_controller.rb:18:in `create'
   ActionText::RichText Create (6.0ms)  INSERT INTO "action_text_rich_texts" ("name", "body", "record_type", "record_id", "created_at", "updated_at") VALUES ($1, $2, $3, $4, $5, $6) RETURNING "id"  [["name", "body"], ["body", "<div>some message</div>"], ["record_type", "Email"], ["record_id", 2], ["created_at", "2023-01-14 12:45:52.029109"], ["updated_at", "2023-01-14 12:45:52.029109"]]
   ↳ app/controllers/emails_controller.rb:18:in `create'
   ActiveStorage::Attachment Load (3.0ms)  SELECT "active_storage_attachments".* FROM "active_storage_attachments" WHERE "active_storage_attachments"."record_id" = $1 AND "active_storage_attachments"."record_type" = $2 AND "active_storage_attachments"."name" = $3  [["record_id", 233], ["record_type", "ActionText::RichText"], ["name", "embeds"]]
   ↳ app/controllers/emails_controller.rb:18:in `create'
   Email Update (16.3ms)  UPDATE "emails" SET "updated_at" = $1 WHERE "emails"."id" = $2  [["updated_at", "2023-01-14 12:45:52.040717"], ["id", 2]]
   ↳ app/controllers/emails_controller.rb:18:in `create'
   TRANSACTION (3.3ms)  COMMIT
   ↳ app/controllers/emails_controller.rb:18:in `create'
 [ActiveJob] Enqueued ActionMailer::MailDeliveryJob (Job ID: 0450db20-369e-4630-aed4-fe27d036bd62) to Async(default) with arguments: "ApplicantMailer", "contact", "deliver_now", {:args=>[{:email=>#<GlobalID:0x000000010c3ace58 @uri=#<URI::GID gid://hotwired-ats/Email/2>>}]}
   Rendered shared/_flash.html.erb (Duration: 15.7ms | Allocations: 1129)
 Completed 200 OK in 527ms (Views: 1.9ms | ActiveRecord: 88.5ms | Allocations: 30309)


 [ActiveJob] [ActionMailer::MailDeliveryJob] [0450db20-369e-4630-aed4-fe27d036bd62]   Email Load (2.7ms)  SELECT "emails".* FROM "emails" WHERE "emails"."id" = $1 LIMIT $2  [["id", 2], ["LIMIT", 1]]
 [ActiveJob] [ActionMailer::MailDeliveryJob] [0450db20-369e-4630-aed4-fe27d036bd62] Performing ActionMailer::MailDeliveryJob (Job ID: 0450db20-369e-4630-aed4-fe27d036bd62) from Async(default) enqueued at 2023-01-14T12:45:52Z with arguments: "ApplicantMailer", "contact", "deliver_now", {:args=>[{:email=>#<GlobalID:0x000000010c414940 @uri=#<URI::GID gid://hotwired-ats/Email/2>>}]}
 [ActiveJob] [ActionMailer::MailDeliveryJob] [0450db20-369e-4630-aed4-fe27d036bd62]   Applicant Load (4.2ms)  SELECT "applicants".* FROM "applicants" WHERE "applicants"."id" = $1 LIMIT $2  [["id", 278], ["LIMIT", 1]]
 [ActiveJob] [ActionMailer::MailDeliveryJob] [0450db20-369e-4630-aed4-fe27d036bd62]   ↳ app/mailers/applicant_mailer.rb:4:in `contact'
 [ActiveJob] [ActionMailer::MailDeliveryJob] [0450db20-369e-4630-aed4-fe27d036bd62]   User Load (3.3ms)  SELECT "users".* FROM "users" WHERE "users"."id" = $1 LIMIT $2  [["id", 26], ["LIMIT", 1]]
 [ActiveJob] [ActionMailer::MailDeliveryJob] [0450db20-369e-4630-aed4-fe27d036bd62]   ↳ app/mailers/applicant_mailer.rb:5:in `contact'
 [ActiveJob] [ActionMailer::MailDeliveryJob] [0450db20-369e-4630-aed4-fe27d036bd62]   Rendering layout layouts/mailer.html.erb
 [ActiveJob] [ActionMailer::MailDeliveryJob] [0450db20-369e-4630-aed4-fe27d036bd62]   Rendering applicant_mailer/contact.html.erb within layouts/mailer
 [ActiveJob] [ActionMailer::MailDeliveryJob] [0450db20-369e-4630-aed4-fe27d036bd62]   ActionText::RichText Load (5.1ms)  SELECT "action_text_rich_texts".* FROM "action_text_rich_texts" WHERE "action_text_rich_texts"."record_id" = $1 AND "action_text_rich_texts"."record_type" = $2 AND "action_text_rich_texts"."name" = $3 LIMIT $4  [["record_id", 2], ["record_type", "Email"], ["name", "body"], ["LIMIT", 1]]
 [ActiveJob] [ActionMailer::MailDeliveryJob] [0450db20-369e-4630-aed4-fe27d036bd62]   ↳ app/views/applicant_mailer/contact.html.erb:1
 [ActiveJob] [ActionMailer::MailDeliveryJob] [0450db20-369e-4630-aed4-fe27d036bd62]   Rendered /Users/dbaron/.rbenv/versions/3.1.2/lib/ruby/gems/3.1.0/gems/actiontext-7.0.4/app/views/action_text/contents/_content.html.erb within layouts/action_text/contents/_content (Duration: 29.7ms | Allocations: 565)
 [ActiveJob] [ActionMailer::MailDeliveryJob] [0450db20-369e-4630-aed4-fe27d036bd62]   Rendered applicant_mailer/contact.html.erb within layouts/mailer (Duration: 46.0ms | Allocations: 2445)
 [ActiveJob] [ActionMailer::MailDeliveryJob] [0450db20-369e-4630-aed4-fe27d036bd62]   Rendered layout layouts/mailer.html.erb (Duration: 84.6ms | Allocations: 2685)
 [ActiveJob] [ActionMailer::MailDeliveryJob] [0450db20-369e-4630-aed4-fe27d036bd62]   Rendering layout layouts/mailer.text.erb
 [ActiveJob] [ActionMailer::MailDeliveryJob] [0450db20-369e-4630-aed4-fe27d036bd62]   Rendering applicant_mailer/contact.text.erb within layouts/mailer
 [ActiveJob] [ActionMailer::MailDeliveryJob] [0450db20-369e-4630-aed4-fe27d036bd62]   Rendered applicant_mailer/contact.text.erb within layouts/mailer (Duration: 9.3ms | Allocations: 617)
 [ActiveJob] [ActionMailer::MailDeliveryJob] [0450db20-369e-4630-aed4-fe27d036bd62]   Rendered layout layouts/mailer.text.erb (Duration: 11.5ms | Allocations: 849)
 [ActiveJob] [ActionMailer::MailDeliveryJob] [0450db20-369e-4630-aed4-fe27d036bd62] ApplicantMailer#contact: processed outbound mail in 242.4ms
 [ActiveJob] [ActionMailer::MailDeliveryJob] [0450db20-369e-4630-aed4-fe27d036bd62] Delivered mail 63c2a400aae26_1d3ddc28778bf@Danielas-Mac-mini.local.mail (81.8ms)
 [ActiveJob] [ActionMailer::MailDeliveryJob] [0450db20-369e-4630-aed4-fe27d036bd62] Date: Sat, 14 Jan 2023 07:45:52 -0500
 From: test1@example.com
 To: freddy_jast@example.org
 Message-ID: <63c2a400aae26_1d3ddc28778bf@Danielas-Mac-mini.local.mail>
 Subject: test
 Mime-Version: 1.0
 Content-Type: multipart/alternative;
  boundary="--==_mimepart_63c2a4008c21a_1d3ddc28777ae";
  charset=UTF-8
 Content-Transfer-Encoding: 7bit


 ----==_mimepart_63c2a4008c21a_1d3ddc28777ae
 Content-Type: text/plain;
  charset=UTF-8
 Content-Transfer-Encoding: 7bit

 some message

 ----==_mimepart_63c2a4008c21a_1d3ddc28777ae
 Content-Type: text/html;
  charset=UTF-8
 Content-Transfer-Encoding: 7bit

 <!DOCTYPE html>
 <html>
   <head>
     <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
     <style>
       /* Email styles need to be inline */
     </style>
   </head>

   <body>
     <div class="trix-content">
   <div>some message</div>
 </div>

   </body>
 </html>

 ----==_mimepart_63c2a4008c21a_1d3ddc28777ae--

 [ActiveJob] [ActionMailer::MailDeliveryJob] [0450db20-369e-4630-aed4-fe27d036bd62] Performed ActionMailer::MailDeliveryJob (Job ID: 0450db20-369e-4630-aed4-fe27d036bd62) from Async(default) in 463.86ms
```

Optional gem to setup GUI for viewing sent emails in dev: https://github.com/fgrehm/letter_opener_web

## Receive and process inbound email

At this point, a user of ATS can send email to an applicant, but can't view emails they've sent or receive replies.

Will use [ActionMailbox](https://guides.rubyonrails.org/action_mailbox_basics.html) for these.

> Action Mailbox routes incoming emails to controller-like mailboxes for processing in Rails. It ships with ingresses for Mailgun, Mandrill, Postmark, and SendGrid. You can also handle inbound mails directly via the built-in Exim, Postfix, and Qmail ingresses.

> The inbound emails are turned into InboundEmail records using Active Record and feature lifecycle tracking, storage of the original email on cloud storage via Active Storage, and responsible data handling with on-by-default incineration.

> These inbound emails are routed asynchronously using Active Job to one or several dedicated mailboxes, which are capable of interacting directly with the rest of your domain model.

For ATS, will keep it simple with single mailbox for rouring inbound email replies from applicants.

Install:

```
rails action_mailbox:install
```

Output:

```
Copying application_mailbox.rb to app/mailboxes
      create  app/mailboxes/application_mailbox.rb
       rails  railties:install:migrations FROM=active_storage,action_mailbox
Copied migration 20230114132135_create_action_mailbox_tables.action_mailbox.rb from action_mailbox
```

Migrate database and create new mailbox ApplicantReplies:

```
rails db:migrate
rails g mailbox ApplicantReplies
```

Output:

```
== 20230114132135 CreateActionMailboxTables: migrating ========================
-- create_table(:action_mailbox_inbound_emails)
   -> 0.0440s
== 20230114132135 CreateActionMailboxTables: migrated (0.0441s) ===============

create  app/mailboxes/applicant_replies_mailbox.rb
```

Left at: The installer automatically adds an