#!/usr/bin/env ruby
  # == Synopsis  
  # WARNING WARNING THIS IS NOT READY FOR USE.
  #
  # This script is designed to automate security analysis of a Kubernetes cluster based on the CIS Kubernetes Standard
  # it makes use of kubeclient - https://github.com/abonas/kubeclient to access the API
  #
  # == Author
  # Author::  Rory McCune
  # Copyright:: Copyright (c) 2017 Rory Mccune
  # License:: GPLv3
  #
  # This program is free software: you can redistribute it and/or modify
  # it under the terms of the GNU General Public License as published by
  # the Free Software Foundation, either version 3 of the License, or
  # (at your option) any later version.
  #
  # This program is distributed in the hope that it will be useful,
  # but WITHOUT ANY WARRANTY; without even the implied warranty of
  # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  # GNU General Public License for more details.
  #
  # You should have received a copy of the GNU General Public License
  # along with this program.  If not, see <http://www.gnu.org/licenses/>.
  #
  # == Options
  #   -h, --help            Displays help message
  #   -v, --version         Display the version, then exit
  #   -s, --server          The target server to connect to in the format https://server_ip:server_port
  #   -r <file>, --report <file>        Name of file for reporting
  #   --reportDirectory <dir>   Place the report in a different directory
  #
  # == Usage 
  #
  #   kubernetesanalyzer.rb -s <API Server endpoint> -r <reportfile> -t <bearer-token to use>
  
class KubernetesAnalyzer
    VERSION = '0.0.1'

  def initialize(commmand_line_opts)
    @options = commmand_line_opts
    require 'logger'
    begin
      require 'kubeclient'
    rescue LoadError
      puts "You need to install kubeclient for this, try 'gem install kubeclient'"
      exit
    end

    @base_dir = @options.report_directory
    if !File.exists?(@base_dir)
      Dir.mkdirs(@base_dir)
    end

    @log = Logger.new(@base_dir + '/kube-analyzer-log.txt')
    @log.level = Logger::DEBUG
    @log.debug("Log created at " + Time.now.to_s)
    @log.debug("Target API Server is " + @options.target_server)

    @report_file_name = @base_dir + '/' + @options.report_file
    @report_file = File.new(@report_file_name + '.txt','w+')
    @log.debug("New Report File created #{@report_file_name}")
  end

  def run
    #TODO: Expose this as an option rather than hard-code to off
    ssl_options = { verify_ssl: OpenSSL::SSL::VERIFY_NONE}
    #TODO: Need to setup the other authentication options
    auth_options = { bearer_token: @options.token}

    client = Kubeclient::Client.new @options.target_server, 'v1', auth_options: auth_options, ssl_options: ssl_options
    puts client.get_pods.to_s
  end

end


if __FILE__ == $0
  require 'ostruct'
  require 'optparse'
  options = OpenStruct.new

  options.report_directory = Dir.pwd
  options.report_file = 'kube-parse-report'
  options.target_server = 'http://127.0.0.1:8080'
  options.html_report = false
  options.token = ''

  opts = OptionParser.new do |opts|
    opts.banner = "Kubernetes Auto Analyzer #{KubernetesAnalyzer::VERSION}"

    opts.on("-s", "--server [SERVER]", "Target Server") do |serv|
      options.target_server = serv
    end

    #TODO: Need options for different authentication mechanisms      

    opts.on("-t", "--token [TOKEN]", "Bearer Token to Use") do |token|
      options.token = token
    end
      
    opts.on("-r", "--report [REPORT]", "Report name") do |rep|
      options.report_file = 'nmap_' + rep
    end

    opts.on("--reportDirectory [REPORTDIRECTORY]", "Report Directory") do |rep|
      options.report_directory = rep
    end

    opts.on("-h", "--help", "-?", "--?", "Get Help") do |help|
      puts opts
      exit
    end
      
    opts.on("-v", "--version", "get Version") do |ver|
      puts "Kubernetes Analyzer Version #{KubernetesAnalyzer::VERSION}"
      exit
    end
  end

  opts.parse!(ARGV)

  unless (options.token.length > 1)
    puts "No auth token specified"
    puts opts
    exit
  end

  analysis = KubernetesAnalyzer.new(options)
  analysis.run
end