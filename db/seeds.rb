# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

# Player.destroy_all
# Team.destroy_all

# 5.times do
#   Team.create(name: Faker::Sports::Basketball.team)
# end

# teams = Team.all

# 10.times do
#   Player.create(name: Faker::Sports::Basketball.player,
#                 number: rand(1..99),
#                 team: teams[rand(0..4)])
# end

# guest_timezone_offset: TIMEZONE_OFFSETS[Faker::Number.between(from: 0, to: TIMEZONE_OFFSETS.length - 1)],

JOB_STATUSES = %w[draft open closed].freeze
JOB_TYPES = %w[full_time part_time].freeze

APPLICANT_STAGES = %w[application interview offer hire].freeze
APPLICANT_STATUSES = %w[active inactive].freeze

def build_description
  desc = ""
  desc << "<strong>#{Faker::Company.name} #{Faker::Company.suffix}, #{Faker::Company.industry}</strong><br>"
  desc << "#{Faker::Company.catch_phrase}<br>"
  desc << "#{Faker::Company.bs}<br>"
  desc << "<br>"
  desc << "#{Faker::Lorem.paragraph}<br>"
  desc << "#{Faker::Lorem.paragraph}<br>"
  desc << "#{Faker::Lorem.paragraph}<br>"
end

Applicant.destroy_all
Job.destroy_all
User.destroy_all
Account.destroy_all

account1 = Account.create!(name: Faker::Company.name)
account2 = Account.create!(name: Faker::Company.name)

User.create!(email: "test1@example.com",
             password: "123456",
             first_name: Faker::Name.first_name,
             last_name: Faker::Name.last_name,
             account: account1)

User.create!(email: "test2@example.com",
             password: "123456",
             first_name: Faker::Name.first_name,
             last_name: Faker::Name.last_name,
             account: account2)

10.times do
  Job.create!(title: Faker::Job.title,
              status: JOB_STATUSES[Faker::Number.between(from: 0, to: 2)],
              job_type: JOB_TYPES[Faker::Number.between(from: 0, to: 1)],
              location: Faker::Address.city,
              description: build_description,
              account: account1)

  Job.create!(title: Faker::Job.title,
              status: JOB_STATUSES[Faker::Number.between(from: 0, to: 2)],
              job_type: JOB_TYPES[Faker::Number.between(from: 0, to: 1)],
              location: Faker::Address.city,
              description: build_description,
              account: account2)
end
jobs = Job.all

30.times do
  applied_date = Faker::Date.backward(days: Faker::Number.between(from: 1, to: 90))
  applicant = Applicant.create!(first_name: Faker::Name.first_name,
                                last_name: Faker::Name.last_name,
                                email: Faker::Internet.safe_email,
                                phone: Faker::PhoneNumber.phone_number,
                                stage: APPLICANT_STAGES[Faker::Number.between(from: 0, to: 3)],
                                status: APPLICANT_STATUSES[Faker::Number.between(from: 0, to: 1)],
                                job: jobs[Faker::Number.between(from: 0, to: 19)],
                                created_at: applied_date,
                                updated_at: applied_date)
  applicant.resume.attach(
    io: File.open("resumes/temp-example-1.pdf"),
    filename: "temp-example-1.pdf",
    content_type: "application/pdf"
  )
end
