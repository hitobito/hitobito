# Dynamic invoice items

## Overview

We wan't to be able to provide invoice items, which generate their cost dynamically based on the recipient of the invoice and additional parameters.
Since these are very specific to the given use case, the core provides the foundation on which the wagon can then define their own dynamic invoice items.

## Defining a dynamic invoice item

The core model `InvoiceItem` acts as the base class.

Every dynamic invoice item has to inherit from the base and define certain methods/variables:

| Name                                 | Type                         | Required |
| ------------------------------------ | ---------------------------- | -------- |
| `self.dynamic`                       | `class_attribute`, `boolean` | `true`   |
| `dynamic_cost`                       | `method`                     | `true`   |
| `dynamic_cost_parameter_definitions` | `class_attribute`, `Hash`    | `false`  |

Dynamic invoice items can also have specific validations which will be considered when running, for example, `Invoice::BatchCreate`.

### Parameters

The `InvoiceItem` model provides the `dynamic_cost_parameters` which allow for parameters to be passed onto the `dynamic_cost` method.

#### Default parameters (set in BatchCreate)

- `recipient_id`: Person#id of the recipient
- `group_id`: Group#id in which the invoice will be created

#### Wagon defined parameters

The wagon can then define more parameters which will be rendered into the `InvoiceListsController#new` form

Inside your invoice_items/example.rb:

```
self.dynamic_cost_parameter_definitions = {
  defined_at: :date
}

```

### Adding a new invoice item specific option to the dropdown

To access these invoice items, you can add a new sub link to the `Dropdown::InvoiceNew`.

Inside your wagon.rb:

```
Dropdown::InvoiceNew.add_sub_link(:variable_donation, [InvoiceItem::VariableDonation])

```

The first parameter defines the translation key for your label, the second defines all InvoiceItem types that will be passed on the link.
