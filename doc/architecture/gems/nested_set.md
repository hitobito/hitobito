# Nested Set

[Homepage](https://github.com/collectiveidea/awesome_nested_set)

The "awesome_nested_set" gem is used to manage hierarchical data structures using the nested set model.
This is particularly useful for representing trees or hierarchical data (like categories, organizational charts, etc.)
in a way that allows efficient querying of the hierarchy.

## Examples

To make use of the nested_set we have to add the `acts_as_nested_set` expression. In Hitobito we implement that
with our nested_set Group:

```
included do
  acts_as_nested_set dependent: :destroy
  
  before_save :store_new_display_name
  after_save :move_to_alphabetic_position
end
```

Once we defined that we can manipulate or create nested sets:

```
root1 = Record.create(name: "Root 1")

# Creating child categories
child1 = root1.children.create(name: "Child 1")
child2 = root1.children.create(name: "Child 2")
sub_child1 = child1.children.create(name: "Sub Child 1")

# Moving a node
child2.move_to_child_of(child1)

# Reordering nodes
child1.move_left
child2.move_right
```

## Summary
The `nested_set` gem, also known as `awesome_nested_set`, is used in Rails applications to manage hierarchical data structures using the nested set model. This is particularly useful for representing trees or hierarchical data (like categories, organizational charts, etc.) in a way that allows efficient querying of the hierarchy.

### Key Features of `nested_set`:

1. **Hierarchical Data Management**: Easily manage tree structures with nested sets.
2. **Efficient Queries**: Perform efficient read operations to fetch ancestors, descendants, siblings, and sub-trees.
3. **Easy Manipulation**: Add, move, and reorder nodes within the hierarchy with minimal queries.

### Installation

To use `nested_set` in your Rails application, follow these steps:

1. **Add the gem to your Gemfile**:
   ```ruby
   gem 'awesome_nested_set'
   ```

2. **Run bundle install**:
   ```sh
   bundle install
   ```

3. **Generate the necessary migrations**:
   You'll need to add `lft`, `rgt`, and optionally `parent_id` columns to the model that will be hierarchical. If you're using ActiveRecord, you can create a migration like this:

   ```sh
   rails generate migration AddNestedSetColumnsToCategories lft:integer rgt:integer parent_id:integer
   ```

4. **Run the migration**:
   ```sh
   rails db:migrate
   ```

5. **Add the Nested Set Behavior to Your Model**:
   ```ruby
   class Category < ApplicationRecord
     acts_as_nested_set
   end
   ```

### Example Usage

Here’s an example of how to use `nested_set` with a `Category` model to manage a hierarchy of categories.

1. **Setup Your Model**:
   Make sure your `Category` model includes `acts_as_nested_set`.

   ```ruby
   # app/models/category.rb
   class Category < ApplicationRecord
     acts_as_nested_set
   end
   ```

2. **Create and Manipulate Categories**:
   Here are some examples of creating and manipulating categories.

   ```ruby
   # Creating root categories
   root1 = Category.create(name: "Root 1")
   root2 = Category.create(name: "Root 2")

   # Creating child categories
   child1 = root1.children.create(name: "Child 1")
   child2 = root1.children.create(name: "Child 2")
   sub_child1 = child1.children.create(name: "Sub Child 1")

   # Moving a node
   child2.move_to_child_of(child1)

   # Reordering nodes
   child1.move_left
   child2.move_right
   ```

3. **Querying the Hierarchy**:

- **Get all descendants**:
  ```ruby
  root1.descendants # Returns all descendants of root1
  ```

- **Get all ancestors**:
  ```ruby
  sub_child1.ancestors # Returns all ancestors of sub_child1
  ```

- **Get siblings**:
  ```ruby
  child1.siblings # Returns all siblings of child1
  ```

- **Get the parent**:
  ```ruby
  sub_child1.parent # Returns the parent of sub_child1
  ```

- **Get all leaves (nodes without children)**:
  ```ruby
  Category.leaves # Returns all leaf nodes
  ```

### Summary

The `nested_set` gem provides a way to efficiently manage and query hierarchical data structures in a Rails application
using the nested set model. By using this gem, you can easily create, move, and query nodes within a tree structure with
minimal performance overhead. This is particularly useful for applications that require complex hierarchical data management,
such as category trees, organizational charts, or threaded comments.
