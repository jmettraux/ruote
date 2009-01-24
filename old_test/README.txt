= OpenWFEru - about the unit tests

There are three tests triggerable by Rake :

   rake test
   rake qtest
   rake ptest

These 3 tests correspond to the following unit test files *

   test/rake_test.rb
   test/rake_qtest.rb
   test/rake_ptest.rb

== test/rake_test.rb

Triggers 'quicktests' and time based tests. Running "rake test" takes 10 seconds more than "rake qtest". These are the 10 seconds necessary to test some time and scheduling aspects of OpenWFEru.

== test/rake_qtest.rb

Runs only 'quick' tests.

== test/rake_ptest.rb

Runs the quicktest but with persistence on. Persistence stores its work file under the work/ directory.
This set of tests takes care of wiping fresh the work/ directory before beginning the tests.

