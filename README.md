Olfactory
==========

### Introduction

Olfactory is a factory extension for creating complex object sets, as a supplement to `factory_girl`, `fabrication`, or other factories.

It introduces the concept of **templates**: an abstract group of objects. You define what objects (or other templates) your template can contain (not unlike a factory), then you can create instances of it by invoking the build or create functions. These templates can be used to make test setup much quicker and easier. Templates are not intended to replace factories, but bridge the gap where `factory_girl` and `fabrication` factories fall short.

They are most useful when:
 - Your models are weakly related or non-relational (e.g. not joined by ActiveRecord associations)
 - You require a collection of objects that are not directly related (or easily built using factories & associations)
 - You'd prefer short-hand notation
 - You'd like to abstract Factory implementation out of your tests
   - e.g. Define a set of generic factories other programmers can use, without requiring them to understand the underlying class or relational structure.

For example, given:
```ruby
context "networkable people" do
  let(:phone_user) { create(:person, :devices => [phone]) }
  let(:phone) { create(:android, apps => [facebook_app_one, twitter_app_one]) } # Factory(:device)
  let(:facebook_phone) { create(:facebook, :platform => :phone) } # Factory(:app)
  let(:twitter_phone) { create(:twitter, :platform => :phone) } # Factory(:app)
  
  let(:tablet_user) { create(:person, :devices => [tablet]) }
  let(:tablet) { create(:tablet, apps => [facebook_tablet]) }  # Factory(:device)
  let(:facebook_tablet) { create(:facebook, :platform => :tablet) }  # Factory(:app)
  
  let(:desktop_user) { create(:person, :devices => [desktop]) }
  let(:desktop) { create(:desktop, apps => [twitter_desktop]) }  # Factory(:device)
  let(:twitter_desktop) { create(:twitter, :platform => :desktop) }  # Factory(:app)
  
  it { expect(phone_user.can_network_with(tablet_user, desktop_user).to be_true }
end
```

This is a lot of setup for a simple test case. We could write a bunch of named factories, but then the test logic simply ends up in a factory file rather than our test; not good.

Instead, we can use templates to define shorthand notation:
```ruby
context "networkable people" do
  let(:user_group) do
    Olfactory.create_template :user_group do |group|
      group.user :desktop_user { |user| user.phone { |phone| phone.apps :facebook, :twitter } }
      group.user :tablet_user { |user| user.tablet { |tablet| tablet.app :facebook } }
      group.user :phone_user { |user| user.desktop { |desktop| desktop.app :twitter } }
    end
  end
  subject { user_group[:users] }
  it { expect(subject[:desktop_user].can_network_with(subject[:tablet_user], subject[:phone_user]).to be_true }
end
```

### Usage

##### Defining templates

Templates are defined in `spec/templates/**/*.rb` files. Define a template using the `Olfactory#template` method.

    Olfactory.template :computer do |t|
      ...
    end

Once defined, these templates can be instantiated using `build_template` and `create_template`, which are analogous to the same `factory_girl`/`fabrication` methods

    Olfactory.build_template :computer # Creates objects, but does not implictly save them
    Olfactory.create_template :computer # Creates objects, and attempts to save all items that respond to #save!

##### #has_one

Defines a field containing a single object.

Definition:
> **has_one** :name *[, :alias => alias_name]*

- `:alias` defines an alias keyword for setting the item value.

When using:
> **name|alias_name** object|&block

Sample:

    # Template definition
    Olfactory.template :computer do |t|
      t.has_one :keyboard
      t.has_one :mouse
      t.has_one :cpu, :alias => :processor
    end
    # Build instance of template
    Olfactory.build_template :computer do |c|
      c.keyboard "X4 Sidewinder"
      c.mouse { FactoryGirl::build(:mouse) }
      c.processor "Intel Xeon"
    end
    # Result
    {
      :keyboard => "X4 Sidewinder",
      :mouse => <Mouse>,
      :cpu => "Intel Xeon"
    }

##### #has_many

Defines a collection of objects. Each invocation appends the resulting items to the collection. Collection is `nil` by default (if no items are added.)

Definition:
> **has_many** :name *[, :alias => alias_name,
>                   :singular => singular_name,
>                   :named => true|false]*

- `:alias` defines an alias keyword for adding mutiple items to the collection.
- `:singular` defines the keyword for adding singular items to the collection.
- `:named` converts the collection to a `Hash`. When true, all invocations must provide a name (first argument.)

When using as generic collection (`named == false`):
> Singular:
>
> **singular_name** Object
> 
> **singular_name** { &block }
>
> Plural:
> 
> **name|alias_name** quantity:Integer { &block }
> 
> **name|alias_name** objects:Array
> 
> **name|alias_name** object1, object2...

When using as a named collection(`named == true`):
> Singular:
>
> **singular_name** variable_name, Object
> 
> **singular_name** variable_name { &block }
>
> Plural:
> 
> **name|alias_name** Hash

Sample:

    # Template definition
    Olfactory.template :computer do |t|
      # Generic
      t.has_many :cpus
      t.has_many :memory_sticks, :singular => :memory_stick
      
      t.has_many :usb_ports
      
      # Named
      t.has_many :drives, :singular => :drive, :named => true
    end
    # Build instance of template
    Olfactory.build_template :computer do |c|
      # Generic
      c.cpus "Intel i7", "Onboard graphics"
      c.memory_stick "2GB"
      c.memory_stick "2GB"
      c.usb_ports 2 do
        "2.0"
      end
      c.usb_ports ["2.0", "2.0"]
      c.usb_ports "3.0", "3.0"
      
      # Named
      c.drive :ssd "Samsung"
      c.drives { :hdd => "Seagate", :optical => "Memorex" }
    end
    # Result
    {
      :cpus => ["Intel i7", "Onboard graphics"],
      :memory_sticks => ["2GB", "2GB"],
      :drives => {
        :ssd => "Samsung",
        :hdd => "Seagate",
        :optical => "Memorex"
      },
      :usb_ports => ["2.0", "2.0", "2.0", "2.0", "3.0", "3.0"]
    }
    
##### #embeds_one

Defines a field containing an embedded template.

Definition:
> **embeds_one** :name *[, :alias => alias_name, :template => template_name]*

- `:alias` defines an alias keyword for setting the embedded template value.
- `:template` defines the actual name of the template used, if it does not match the name.

When using:
> **name|alias_name** *[preset_name, { &block }]*

Sample:

    # Template definition
    Olfactory.template :computer do |t|
      t.embeds_one :cpu
      t.embeds_one :gpu, :template => :cpu
    end
    Olfactory.template :cpu do |t|
      t.has_many :cores
      preset :amd do |p|
        p.cores "AMD Core", "AMD Core"
      end
    end
    # Build instance of template
    Olfactory.build_template :computer do |computer|
      computer.cpu do |cpu|
        cpu.cores "Intel Core", "Intel Core"
      end
      computer.gpu :amd
    end
    # Result
    {
      :cpu => {
                :cpu_core => ["Intel Core", "Intel Core"]
              },
      :gpu => {
                :gpu_core => ["AMD Core", "AMD Core"]
              }
    }
    
##### #embeds_many

Defines a collection of templates. Each invocation appends the resulting templates to the collection. Collection is `nil` by default (if no templates are added.)

Definition:
> **has_many** :name *[, :alias => alias_name,
>                   :template => template_name,
>                   :singular => singular_name,
>                   :named => true|false]*

- `:alias` defines an alias keyword for adding mutiple templates to the collection.
- `:template` defines the actual name of the template used, if it does not match the name.
- `:singular` defines the keyword for adding singular templates to the collection.
- `:named` converts the collection to a `Hash`. When true, all invocations must provide a name (first argument.)

When using as generic collection (`named == false`):
> Singular:
>
> **singular_name**
> 
> **singular_name** preset_name
>
> **singular_name** { &block }
>
> Plural:
> 
> **name|alias_name** quantity:Integer
> 
> **name|alias_name** preset_name, quantity:Integer
> 
> **name|alias_name** quantity:Integer, preset_name
> 
> **name|alias_name** quantity:Integer { &block }

When using as a named collection(`named == true`):
> Singular:
> 
> **singular_name** variable_name
>
> **singular_name** variable_name, preset_name
> 
> **singular_name** variable_name { &block }
>
> Plural:
> 
> (None)

Sample:

    # Template definition
    Olfactory.template :computer do |t|
      # Generic
      t.embeds_many :cpus, :singular => :cpu
      t.embeds_many :drives, :singular => :drive, :named => true
    end
    Olfactory.template :cpu do |t|
      # Generic
      t.has_many :cores, :singular => :core
      t.preset :amd do |p|
        p.cores "AMD Core", "AMD Core"
      end
    end
    Olfactory.template :drive do |t|
      # Generic
      t.has_one :storage_size
      t.has_one :manufacturer
      t.preset :samsung_512gb do |p|
        p.storage_size 512000
        p.manufacturer "Samsung"
      end
    end
    # Build instance of template
    Olfactory.build_template :computer do |c|
      # Generic
      computer.cpu :amd
      computer.cpu do |cpu|
        cpu.cores "Intel Core", "Intel Core"
      end
      computer.cpus 2 # Creates 2 :cpu templates with defaults
      computer.cpus :amd, 2
      computer.cpus 2, :amd
      computer.cpus 2 do |cpu|
        cpu.cores "Intel Core", "Intel Core"
      end
      
      # Named
      computer.drive :hdd # Creates :drive template with defaults
      computer.drive :ssd, :samsung_512gb
      computer.drive :optical do |drive|
        drive.manufacturer "Memorex"
      end
    end

##### #preset

Defines a preset of values.

Definition:
> **preset** :name { |instance| &block }

When using:
> Olfactory.build_template template_name, :preset => preset_name, :quantity => quantity:Integer

See above sections for usage within templates.

Sample:

    # Template definition
    Olfactory.template :computer do |t|
      t.embeds_many :cpus
      t.preset :dual_core do |p|
        p.cpus 2 do |cpu|
          cpu.core "Intel Core"
        end
      end
    end
    Olfactory.template :cpu do |t|
      t.has_one :cpu_core
    end
    # Build instance of template
    Olfactory.build_template :computer, :preset => :dual_core
    # Result
    {
      :cpus => [{
                :cpu_core => "Intel Core"
              },
              {
                :cpu_core => "Intel Core"
              }]
    }
    
##### #macro
 
**TODO: Fill in this section...**

##### #transient
 
**TODO: Fill in this section...**

##### Defaults: #before & #after

Defines default values, which are used to fill in any empty `has`, `embeds` or `transient` fields, before and after respectively. They will *not* overwrite any non-nil value.

Definition:
> **before** { |instance| &block }
> **after** { |instance| &block }

Sample:

    # Template defintion
    Olfactory.template :computer do |t|
      t.has_one :cpu
      t.has_one :memory_size
      t.before do |d|
        d.cpu "Intel Xeon"
        d.memory_size "4GB"
      end
    end
    Olfactory.template :phone do |t|
      t.has_one :cpu
      t.has_one :memory_size
      t.after do |d|
        d.cpu "ARM"
        d.memory_size "2GB"
      end
    end
    
    # Build instance of template
    Olfactory.build_template :computer do |c|
      c.cpu "AMD Athlon"
    end
    # Result 
    {
      :cpu => "AMD Athlon",
      :memory_size => "4GB"
    }
    
    # Build instance of template
    Olfactory.build_template :phone do |c|
      c.memory_size "1GB"
    end
    # Result 
    {
      :cpu => "ARM",
      :memory_size => "1GB"
    }
