# Rails Conventions

This document defines coding conventions for this Rails application. Follow these patterns to maintain consistency and leverage Rails' built-in functionality.

---

## Views

### Use Rails Helpers Over Raw HTML

Always prefer Rails view helpers over native HTML elements. They provide CSRF protection, proper routing, and Turbo integration out of the box.

#### Links

```erb
<!-- Bad -->
<a href="/users">Users</a>
<a href="<%= user_path(@user) %>">View</a>

<!-- Good -->
<%= link_to "Users", users_path %>
<%= link_to "View", @user %>
```

#### Buttons & Forms

```erb
<!-- Bad -->
<button onclick="...">Delete</button>
<form action="/users" method="post">

<!-- Good -->
<%= button_to "Delete", @user, method: :delete %>
<%= form_with model: @user do |f| %>
```

#### Images

```erb
<!-- Bad -->
<img src="/images/logo.png" alt="Logo">

<!-- Good -->
<%= image_tag "logo.png", alt: "Logo" %>
```

#### Form Inputs

```erb
<!-- Bad -->
<input type="email" name="user[email]" value="<%= @user.email %>">
<select name="user[role]">...</select>

<!-- Good -->
<%= f.email_field :email %>
<%= f.select :role, User::ROLES %>
```

### Form Conventions

Always use `form_with` with a model when possible:

```erb
<!-- Preferred: model-backed form -->
<%= form_with model: @user, class: "space-y-4" do |f| %>
  <%= f.label :email %>
  <%= f.email_field :email %>
  <%= f.submit %>
<% end %>

<!-- URL-based form (when no model) -->
<%= form_with url: search_path, method: :get do |f| %>
  <%= f.text_field :q %>
<% end %>
```

### Partials

- Name partials with leading underscore: `_form.html.erb`
- Use locals, not instance variables in partials
- Use `render` shorthand when possible

```erb
<!-- Bad -->
<%= render partial: "user", locals: { user: @user } %>

<!-- Good -->
<%= render @user %>
<%= render @users %>  <!-- renders _user.html.erb for each -->
<%= render "form", user: @user %>
```

---

## Controllers

### RESTful Actions

Stick to the 7 RESTful actions when possible. Create new controllers rather than adding custom actions.

```ruby
# Bad: Custom action in existing controller
class UsersController < ApplicationController
  def activate
  def deactivate
  def export
end

# Good: Separate controllers for separate concerns
class Users::ActivationsController < ApplicationController
  def create   # activate
  def destroy  # deactivate
end

class Users::ExportsController < ApplicationController
  def show
end
```

### Strong Parameters

Define permitted params in a private method:

```ruby
class UsersController < ApplicationController
  def create
    @user = User.new(user_params)
    # ...
  end

  private

  def user_params
    params.require(:user).permit(:email, :name, :role)
  end
end
```

### Before Actions

Use sparingly. Prefer explicit calls for clarity:

```ruby
# Acceptable for common patterns
before_action :set_user, only: [:show, :edit, :update, :destroy]

# Avoid chaining many before_actions - makes flow hard to follow
```

### Respond To Formats

For Turbo-enabled apps, HTML is usually sufficient. Add formats only when needed:

```ruby
def create
  @user = User.new(user_params)
  if @user.save
    redirect_to @user, notice: "Created."
  else
    render :new, status: :unprocessable_entity
  end
end
```

---

## Models

### Validations First

Order model contents: constants, associations, validations, scopes, callbacks, methods.

```ruby
class User < ApplicationRecord
  # Constants
  ROLES = %w[admin member guest].freeze

  # Associations
  belongs_to :organization
  has_many :posts, dependent: :destroy

  # Validations
  validates :email, presence: true, uniqueness: true
  validates :role, inclusion: { in: ROLES }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :admins, -> { where(role: "admin") }

  # Callbacks (use sparingly)
  after_create_commit :send_welcome_email

  # Instance methods
  def admin?
    role == "admin"
  end

  private

  def send_welcome_email
    UserMailer.welcome(self).deliver_later
  end
end
```

### Query Methods

Use scopes for reusable queries. Keep them simple and chainable:

```ruby
# Good: Simple, composable scopes
scope :active, -> { where(active: true) }
scope :recent, -> { order(created_at: :desc) }
scope :by_role, ->(role) { where(role: role) }

# Usage
User.active.recent.by_role("admin")
```

### Avoid Callbacks When Possible

Callbacks create hidden complexity. Prefer explicit service objects for complex operations:

```ruby
# Avoid: Hidden side effects
after_create :create_organization, :send_emails, :notify_slack

# Prefer: Explicit in controller/service
def create
  @user = User.new(user_params)
  if @user.save
    CreateUserOrganization.call(@user)
    UserMailer.welcome(@user).deliver_later
  end
end
```

### Use `presence` and `blank?`

```ruby
# Bad
if name != nil && name != ""

# Good
if name.present?
if name.blank?
name.presence || "Anonymous"
```

---

## Hotwire (Turbo + Stimulus)

### Turbo First, Minimal JavaScript

Always try to solve problems with Turbo before reaching for custom JavaScript. The goal is to write as little JavaScript as possible while still delivering a modern, responsive user experience.

**Order of preference:**
1. Server-rendered HTML with Turbo Drive (default, no code needed)
2. Turbo Frames for partial page updates
3. Turbo Streams for multi-element updates
4. Stimulus for small, focused UI behaviors
5. Custom JavaScript only as a last resort

If you find yourself writing more than ~20 lines of JavaScript for a feature, step back and consider if Turbo can handle it instead.

### Turbo Frames

Use frames for partial page updates:

```erb
<!-- Wrap updateable content -->
<%= turbo_frame_tag @user do %>
  <%= render @user %>
<% end %>

<!-- Link that targets the frame -->
<%= link_to "Edit", edit_user_path(@user), data: { turbo_frame: dom_id(@user) } %>
```

### Turbo Streams

For updates to multiple parts of the page:

```erb
<!-- app/views/users/create.turbo_stream.erb -->
<%= turbo_stream.prepend "users", @user %>
<%= turbo_stream.update "user_count", User.count %>
```

### Stimulus Controllers

Keep controllers small and focused:

```javascript
// app/javascript/controllers/toggle_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  toggle() {
    this.contentTarget.classList.toggle("hidden")
  }
}
```

```erb
<div data-controller="toggle">
  <button data-action="toggle#toggle">Show/Hide</button>
  <div data-toggle-target="content">Content here</div>
</div>
```

### Stimulus Naming

- Controller names: lowercase, hyphenated (`clipboard-controller.js`)
- Data attributes: `data-controller`, `data-action`, `data-{controller}-target`
- Actions: `click->controller#method` (click is default for buttons)

### Common Patterns Without Custom JS

These patterns are all achievable with Turbo alone - no JavaScript required:

```erb
<!-- Form submission with inline updates -->
<%= form_with model: @comment do |f| %>
  ...
<% end %>

<!-- Modal/dialog via Turbo Frame -->
<%= link_to "Edit", edit_user_path(@user), data: { turbo_frame: "modal" } %>

<!-- Inline editing -->
<%= turbo_frame_tag dom_id(@post, :title) do %>
  <h1><%= @post.title %></h1>
  <%= link_to "Edit", edit_post_path(@post) %>
<% end %>

<!-- Live updates via Turbo Streams over Action Cable -->
<%= turbo_stream_from @post %>

<!-- Lazy loading -->
<%= turbo_frame_tag "comments", src: post_comments_path(@post), loading: :lazy do %>
  <p>Loading comments...</p>
<% end %>
```

---

## Routes

### RESTful Routes

Use `resources` for standard CRUD:

```ruby
# Good
resources :users
resources :posts, only: [:index, :show]

# Nested resources (max 1 level deep)
resources :users do
  resources :posts, shallow: true
end
```

### Namespaced Routes

Group related controllers:

```ruby
namespace :admin do
  resources :users
  resources :settings, only: [:edit, :update]
end

# For singular resources
resource :profile, only: [:show, :edit, :update]
```

### Named Routes

Use `as:` for clarity when needed:

```ruby
get "login", to: "sessions#new", as: :login
get "signup", to: "registrations#new", as: :signup
```

---

## Background Jobs

### Keep Jobs Simple

Jobs should be small and focused:

```ruby
class SendWelcomeEmailJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    UserMailer.welcome(user).deliver_now
  end
end
```

### Pass IDs, Not Objects

ActiveJob serializes arguments. Pass IDs to avoid serialization issues:

```ruby
# Bad
SendWelcomeEmailJob.perform_later(@user)

# Good
SendWelcomeEmailJob.perform_later(@user.id)
```

---

## Testing (RSpec)

### File Naming

- Model specs: `spec/models/user_spec.rb`
- Request specs: `spec/requests/users_spec.rb`
- System specs: `spec/system/user_registration_spec.rb`

### Describe Blocks

```ruby
RSpec.describe User, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }
  end

  describe "#admin?" do
    context "when role is admin" do
      it "returns true" do
        user = build(:user, role: "admin")
        expect(user.admin?).to be true
      end
    end
  end
end
```

### Use Factories

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    name { Faker::Name.name }

    trait :admin do
      role { "admin" }
    end
  end
end

# Usage
create(:user)
create(:user, :admin)
build(:user, email: "test@example.com")
```

---

## General

### Prefer Rails Defaults

Don't fight the framework. Use Rails conventions unless there's a compelling reason not to.

### Avoid Magic Strings

Use constants or enums:

```ruby
# Bad
if user.role == "admin"

# Good
if user.admin?
# or
if user.role == User::ROLE_ADMIN
```

### Use `&.` Safe Navigation

```ruby
# Bad
user && user.profile && user.profile.avatar

# Good
user&.profile&.avatar
```

### Prefer `||=` for Memoization

```ruby
def current_user
  @current_user ||= User.find(session[:user_id])
end
```
