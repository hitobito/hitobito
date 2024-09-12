# CanCanCan
[Homepage](https://github.com/CanCanCommunity/cancancan?tab=readme-ov-file)

This gem is our authorization library which restricts what resources a given user is allowed to access. The permissions
can be defined in one or multiple "ability files" and can not be duplicated across multiple controllers.

## Example in Hitobito
To get into this logic whe start with looking at our ability.rb file:

```
def define_root_abilities
can :manage, :all
# root cannot change her email, because this is what makes her root.
  cannot :update_email, Person do |p|
    p.root?
  end
end
```

In this method we define our root abilities with the use of cancancan.
The command to give a user certain permissions follows the given pattern:

can `actions`, `subjects`, `conditions`

In this example we let the root manage all entities.

## Check Permissions of entity
After defining our permissions we can check them over a simple if condition:

```
- if can? :read, @post
  =link_to "View", @post
```

## Fetch records

With the permissions defined we are able to use the method `accessible_by` method which returns all
records which can be accessed by the current user. These permissions are given using the

`can :read, record` expression

An example of this would look something like this:

```
def index
  @articles = Article.accessible_by(current_ability)
end
```

or

```
def show
  @article = Article.find(params[:id])
  authorize! :read, @article
end
```

