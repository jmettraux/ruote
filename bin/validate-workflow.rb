#!/usr/bin/env ruby
#
# Program Name:  validate-workflow.rb
# Purpose:       A helper script that validates a workflow document against
#                a XML Schema
# Author:        Alain Hoang
# Notes:         Uses Ruby's libxml library to handle the parsing

# Stdlib
require 'net/http'
require 'optparse'
require 'uri'

# From the gems archive
require 'rubygems'
require 'xml/libxml'


module OpenWFEru
    FLOWDEF_URL = 'http://www.openwfe.org/flowdef.xsd'
    # Validates a workflow definition against the Workflow XML Schema
    # defined at http://www.openwfe.org/flowdef.xsd
    class WorkflowValidator
        
        attr_accessor :schema_url
        attr_accessor :args

        # Create a validator object using a WorkflowValidatorArgs object
        def initialize(args)
            @args = args
            @args[:schema_url] ||= FLOWDEF_URL

            xsd_str = Net::HTTP.get URI.parse(@args[:schema_url])
            @schema = XML::Schema.from_string(xsd_str)
        end

        # validates a xml file against the OpenWFE XML Schema
        def validate(file)
	        xmldoc = XML::Document.file(file)
	        xmldoc.validate_schema(@schema)
        end
    end

    class WorkflowValidatorArgs < Hash
        # Create an arguments object to send to a WorkflowValidator object
        def initialize(args)
            super()
            opts = OptionParser.new do |opts|
                opts.banner =  "Usage: #$0 [-u url] <workflow def> [workflow def] ..."
    
                opts.on('-u', '--url URL', 'Use XML Schema at URL') do |url|
                    self[:schema_url] = url
                end
    
                opts.on_tail('-h', '--help', 'display this help and exit') do
                    puts opts
                    exit
                end
            end
            opts.parse!(args)
            # Check for no args and exit if so
            if args.empty?
                puts opts
                exit 1
            end
        end
    end
end


def main
    # Create the arguments object and the validator object
    args = OpenWFEru::WorkflowValidatorArgs.new(ARGV)
    validator = OpenWFEru::WorkflowValidator.new(args)

    # Loop through all arguments and validate the file
	ARGV.each do |f|
        print "Trying to validate #{f}...  "
        if FileTest.exists?(f) && validator.validate(f)
            print "PASSED\n"
        else
            print "FAILED\n"
        end
	end
end

if $0 == __FILE__
    main
end
