#!/usr/bin/env ruby
#
# createstackmoduleoutputs.rb
# Author: erhard.wais@boehringer-ingelheim.com
#
# This script creates terraform code required for the new testing strategy.
# It parses the output from the command in CAPTUREFORM  and identfies which
# blueprints are used for development in order to build the required output
# structure.
# It creates the following files (based on current config)
# - ./stackmodulesoutputs.tf
# - ./test/fixtures/#{myEnv}/moduleoutputs.tf
# - ./test/integration/#{myEnv}/controls/blueprints.rb
# - ./test/integration/#{myEnv}/inspec.yml

require 'json'
require 'open3'

INSPECAWS        = ""
INSPECAWSTAG     = ""
CAPTUREFROMSTACK = 'terraform-config-inspect --json'
ENVNAME          = 'KITCHEN_SUITE_NAME'
OUTPUTSTF        = './stackmodulesoutputs.tf'
BANNER           = "# This file has been created automatically.\n\n"
BANNER2          = "name: stackdefault\n" + "supports:\n" + "  - platform: aws\n" + "depends:\n" + "  - name: inspec-aws\n" + "    git: https://github.com/inspec/inspec-aws\n" + "    tag: v1.33.0\n" + "# Begin - blueprint inspec profiles\n"

stdout, stderr, status = Open3.capture3(CAPTUREFROMSTACK)

myEnv         = ENV.fetch(ENVNAME,"default")
moduleNames   = Hash.new
moduleSources = Hash.new
uniqueBP      = Hash.new(0)

CAPTUREFROMFIXTURE   = "terraform-config-inspect ./test/fixtures/#{myEnv} --json"

stdoutfixture, stderrfixture, statusfixture = Open3.capture3(CAPTUREFROMFIXTURE)

stackName   = File.basename(Dir.getwd)
outputTF    = File.open(OUTPUTSTF, 'w')
modoutTF    = File.open("./test/fixtures/#{myEnv}/moduleoutputs.tf", 'w')
allBPsRB    = File.open("./test/integration/#{myEnv}/controls/blueprints.rb", 'w')
inspecYML   = File.open("./test/integration/#{myEnv}/inspec.yml", 'w')

outputTF.write(BANNER)
modoutTF.write(BANNER)
allBPsRB.write(BANNER)
inspecYML.write(BANNER)
inspecYML.write(BANNER2)

# get module section from main.json
allModules = JSON.parse(stdout)['module_calls']
allModulesfixtures = JSON.parse(stdoutfixture)['module_calls']

fixturemodulename = ""
allModulesfixtures.each do |singleModule|
  fixturemodulename = singleModule[0]
end

# for each module
allModules.each do |singleModule|

  # get modulename and attributes
  name      = singleModule[0]
  attribute = singleModule[1]

  moduleOut    = name
  moduleValue  = "#{name}.*"
  fileName     = attribute['source']
  moduleBP     = File.basename(fileName[0..fileName.index('git?ref')], ".*")

  # create helper hashes to track which module uses which BP and how often
  moduleNames[moduleOut]  = moduleBP
  moduleSources[moduleBP] = fileName
  uniqueBP[moduleBP]     += 1

# create outputX.tf
 outputTF.write("output \"module_#{moduleOut.gsub(/-/,"_")}\" {\n")
 outputTF.write("  value = module.#{moduleValue}\n}\n")
end

# create moduleoutputs.tf
stackOut   = stackName.gsub(/-/,"_")
stackValue = "module.#{stackOut}_default"

modoutTF.write("output \"module_#{stackOut}\" {\n")
modoutTF.write("  value = module.#{fixturemodulename}.*\n}\n")

uniqueBP.each do |name, count|
  duplicates   = Array.new

  moduleNames.select { |k, v| v == name }.keys.each {|dup| duplicates << dup}

  if count == 1
    moduleValue = "module.#{fixturemodulename}.module_#{duplicates[0].gsub(/-/,"_")}.*"
    moduleV2    = "module.#{duplicates[0]}.*"
  else
    moduleValue = "concat("
    duplicates.each_index {|i| moduleValue += "module.#{fixturemodulename}.module_#{duplicates[i].gsub(/-/,"_")}.*,"}
    moduleValue = moduleValue[0...-1] + ")"

    moduleV2 = "concat("
    duplicates.each_index {|i| moduleV2 += "module.#{duplicates[i]}.*,"}
    moduleV2 = moduleV2[0...-1] + ")"
  end

  moduleOut    = name.gsub(/-/,"_")
  modoutTF.write( "output \"module_#{moduleOut}\" {\n")
  modoutTF.write( "  value = #{moduleValue}\n}\n")

  # write stackmoduleoutputs.tf
  outputTF.write("output \"module_#{moduleOut.gsub(/-/,"_")}\" {\n")
  outputTF.write("  value = #{moduleV2}\n}\n")

  # read the source/filename from the helper hash
  fileName  = moduleSources.select { |k, v| k == name }[name]

  # check if is repository and if it is a BI blueprint
  hasGit    = fileName.index('git::')
  hasGitRef = fileName.index('.git?ref')
  isBP      = fileName.index('blueprint')

  if isBP
    # write blueprints.rb
    allBPsRB.write("include_controls '#{moduleOut}'\n")

    # write inspec.yml
    inspecYML.write("  - name: #{moduleOut}\n")

    if hasGit
      # puts " ... Tag      #{fileName[(hasGitRef + 9)..]} "
      # puts " ... url      #{fileName[(hasGit + 5)..(hasGitRef + 3)]} "
      # add +9 = length of .git?ref + 1
      inspecYML.write("    git: #{fileName[(hasGit + 5)..(hasGitRef + 3)]}\n")
      inspecYML.write("    tag: #{fileName[(hasGitRef + 9)..]}\n")
      inspecYML.write("    relative_path: test/integration/#{myEnv}\n")
    else
      inspecYML.write("    path: ../../../#{fileName}\n")
    end
  end
end

outputTF.close unless outputTF.nil?
modoutTF.close unless modoutTF.nil?
allBPsRB.close unless allBPsRB.nil?
inspecYML.close unless allBPsRB.nil?

# pretty format modified tf files, so that a cyclic execution of terraform fmt is prohibited.
TFFMT = "terraform fmt"
stdouttffmt, stderrtffmt, statustffmt = Open3.capture3(TFFMT)
pp stdouttffmt
pp stderrtffmt
pp statustffmt
