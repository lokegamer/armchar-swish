# armchar-swish

ArM character server implementation using Haskell and Swish.

## Problems

There are several limitations in Swish compared to Jena
As far as I can tell:

+ No prebuilt OWL and RDFS reasoners.  
+ No ready to use function to apply rulesets.
+ Rules cannot easily be defined in a separate file in a separate
  rules language.  The focus of Swish has been the script language.
+ No JSON-LD support
+ No noValue clause

## Needs for Reasoning

+ Implied Traits defined in Ontology.
  (E.g. Virtues granting abilities or other virtues.)
+ Copy data from other resources
    - abilities inherit description from class
    - character inherit data from covenant or saga
+ Filter on classes.
+ Query

## TODO

1. Hand-code XP/score calculation rules.
2. Spell String Rules
3. Advancement Rules
4. Make both hasTrait and subproperties
5. Query Advancements
