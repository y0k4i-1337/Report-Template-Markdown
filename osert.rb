#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'fileutils'
require 'date'
require 'shellwords'

colors = {
  red: "\e[31m",
  nocolor: "\e[0m"
}

certifications = [
  {
    exam: 'OSCP',
    template: [
      {
        name: 'Whoisflynn Improved Template v3.2',
        path: 'src/OSCP-exam-report-template_whoisflynn_v3.2.md'
      },
      {
        name: 'Official Offensive Security Template v1',
        path: 'src/OSCP-exam-report-template_OS_v1.md'
      },
      {
        name: 'Official Offensive Security Template v2',
        path: 'src/OSCP-exam-report-template_OS_v2.md'
      }
    ]
  },
  {
    exam: 'OSWA',
    template: [
      {
        name: 'Official Offensive Security Template v1',
        path: 'src/OSWA-exam-report-template_OS_v1.md'
      }
    ]
  },
  {
    exam: 'OSWE',
    template: [
      {
        name: 'Official Offensive Security Template v1',
        path: 'src/OSWE-exam-report-template_OS_v1.md'
      },
      {
        name: 'Noraj Improved Template v1',
        path: 'src/OSWE-exam-report-template_noraj_v1.md'
      },
      {
        name: 'XL-SEC Improved Template v1',
        path: 'src/OSWE-exam-report-template_xl-sec_v1.md'
      }
    ]
  },
  {
    exam: 'OSCE',
    template: [
      {
        name: 'Official Offensive Security Template v1',
        path: 'src/OSCE-exam-report-template_OS_v1.md'
      }
    ]
  },
  {
    exam: 'OSEE',
    template: [
      {
        name: 'Official Offensive Security Template v1',
        path: 'src/OSEE-exam-report-template_OS_v1.md'
      }
    ]
  },
  {
    exam: 'OSWP',
    template: [
      {
        name: 'Official Offensive Security Template v1',
        path: 'src/OSWP-exam-report-template_OS_v1.md'
      }
    ]
  },
  {
    exam: 'OSED',
    template: [
      {
        name: 'Official Offensive Security Template v1',
        path: 'src/OSED-exam-report-template_OS_v1.md'
      },
      {
        name: 'Epi Improved Template v1',
        path: 'src/OSED-exam-report-template_epi_v1.md'
      }
    ]
  },
  {
    exam: 'OSEP',
    template: [
      {
        name: 'Official Offensive Security Template v1',
        path: 'src/OSEP-exam-report-template_OS_v1.md'
      },
      {
        name: 'Ceso Improved Template v1',
        path: 'src/OSEP-exam-report-template_ceso_v1.md'
      }
    ]
  },
  {
    exam: 'OSDA',
    template: [
      {
        name: 'Official Offensive Security Template v1',
        path: 'src/OSDA-exam-report-template_OS_v1.md'
      }
    ]
  },
  {
    exam: 'OSMR',
    template: [
      {
        name: 'Official Offensive Security Template v1',
        path: 'src/OSMR-exam-report-template_OS_v1.md'
      }
    ]
  },
  {
    exam: 'OSTH',
    template: [
      {
        name: 'Official Offensive Security Template v1',
        path: 'src/OSTH-exam-report-template_OS_v1.md'
      }
    ]
  },
  {
    exam: 'OSIR',
    template: [
      {
        name: 'Official Offensive Security Template v1',
        path: 'src/OSIR-exam-report-template_OS_v1.md'
      }
    ]
  }
]

custom = [
  {
    type: 'Black Box Penetration Test',
    template: [
      {
        name: 'y0k4i Black Box Template v1',
        path: 'src/BlackBoxPenTest-report-template_y0k4i_v1.md'
      }
    ]
  }
]

options = {
  'resource-path': '.'
}

subtext = <<~HELPMSG
  Markdown Templates for Offensive Security OSCP, OSWE, OSEE, OSWP, OSEP, OSED Exam and Custom Reports.

  Sub-commands:
    init     :  Copy a template that you will use to write your report
    generate :  Generate your PDF report and 7z archive

  See 'osert COMMAND --help' for more information on a specific command.
HELPMSG

global = OptionParser.new do |opts|
  opts.banner = 'Usage: osert <subcommand> [options]'
  opts.separator ''
  opts.separator subtext
end

subcommands = {
  'init' => OptionParser.new do |opts|
    opts.banner = 'Usage: osert init [options]'
    opts.on('-o', '--output REPORT', 'File path to store a copy of the template to write your report')
  end,
  'generate' => OptionParser.new do |opts|
    opts.banner = 'Usage: osert generate [options]'
    opts.on('-i', '--input REPORT', 'File path to the markdown report to convert to PDF')
    opts.on('-o', '--output PDF', 'File path to store the PDF report')
    opts.on('-e', '--exam EXAM', 'The exam short name')
    opts.on('-s', '--osid OSID', 'Your Offensive Security ID')
    opts.on('--no-osid', 'Do not ask for OSID (useful for custom templates)') do
      options[:no_osid] = true
    end
    opts.on('--no-labreport', 'Do not ask to include lab report') do
      options[:no_labreport] = true
    end
    opts.on('--preview', 'Open the generated PDF report') do
      options[:preview] = true
    end
    opts.on('--no-preview', 'Do not ask to open the generated PDF report') do
      options[:no_preview] = true
    end
    opts.on('-t', '--theme STYLE', 'Highlight style (theme) to use')
    opts.on('-r', '--resource-path PATH', 'Complementary resources (e.g. images) path to include [Default: ./src]')
  end
}

if ARGV.empty?
  abort(global.help)
else
  global.order!(into: options)
end
command = ARGV.shift
subcommands[command].order!(into: options)

def puts_prompt(*args)
  puts args if args.size == 1
  print '> '
end

def sed(file, text_i, text_o)
  text = File.read(file)
  File.open(file, 'w+') do |f|
    f.puts(text.sub(text_i, text_o))
  end
end

begin
  case command
  when 'init'
    # Choose a template type
    puts '[+] Choose a Template Type:'
    puts '0. Offensive Security'
    puts '1. Custom'
    puts_prompt
    choice = gets.chomp
    if choice == '0'
      # Choose a certification
      puts '[+] Choose a Certification:'
      certifications.each_with_index do |c, i|
        puts "#{colors[:red]}#{i}. #{c[:exam]}#{colors[:nocolor]}"
      end
      puts_prompt
      cert = certifications[gets.chomp.to_i]

      # Choose a template
      puts '[+] Choose a Template:'
      cert[:template].each_with_index do |t, i|
        puts "#{colors[:red]}#{i}. [#{cert[:exam]}] #{t[:name]}#{colors[:nocolor]}"
      end
      puts_prompt
      src = cert[:template][gets.chomp.to_i][:path]

      # Enter your OS id
      puts '[+] Enter your OS ID:'
      print '> OS-'
      osid = "OS-#{gets.chomp}"
    elsif choice == '1'
      # Choose a custom template
      puts '[+] Choose a Report Type:'
      custom.each_with_index do |c, i|
        puts "#{colors[:red]}#{i}. #{c[:type]}#{colors[:nocolor]}"
      end
      puts_prompt
      type = custom[gets.chomp.to_i]

      # Choose a template
      puts '[+] Choose a Template:'
      type[:template].each_with_index do |t, i|
        puts "#{colors[:red]}#{i}. [#{type[:type]}] #{t[:name]}#{colors[:nocolor]}"
      end
      puts_prompt
      src = type[:template][gets.chomp.to_i][:path]
    else
      puts 'Invalid choice. Exiting...'
      exit
    end

    # Enter your email address
    puts_prompt '[+] Enter your email address as author:'
    author = gets.chomp

    if options[:output]
      output = options[:output]
    else
      puts_prompt '[+] Enter the path where you want to copy the report template:'
      output = gets.chomp
    end

    # Check if the output directory exists
    # If not, create it
    unless File.directory?(output)
      puts "[+] Creating directory #{output}..."
      FileUtils.mkdir_p(output)
    end

    # The chosen template will be saved in the chosen directory
    begin
      FileUtils.cp(src, output)
    rescue Errno::ENOENT
      FileUtils.cp("/usr/share/osert/#{src}", output)
    end

    # Replace metadata in the report
    report = "#{output}/#{File.basename(src)}"
    if choice == '0'
      sed(report, /^author:.*/, %(author: ["#{author}"]))
    else
      sed(report, /^author:.*/, %(author: ["#{author}", "OSID: #{osid}"]))
    end
    sed(report, /^date:.*/, %(date: "#{Date.today}"))

    print "[+] The #{colors[:red]}#{File.basename(src)}#{colors[:nocolor]} file is saved in"
    print " #{colors[:red]}#{output}#{colors[:nocolor]} folder."
    puts 'Edit it with your exam notes.'
    print "[+] Then, run #{colors[:red]}osert generate -i #{output}/#{File.basename(src)} -o #{output}#{colors[:nocolor]}"
    puts ' for getting your report.'
  when 'generate'
    puts '[+] Preparing your final report...'

    # Load custom styles from ~/.local/share/pandoc/highlights
    custom_styles = []
    Dir.glob("#{Dir.home}/.local/share/pandoc/highlights/*.theme").each do |file|
      custom_styles << File.basename(file, '.theme')
    end
    styles = `pandoc --list-highlight-styles`.split("\n")
    # Add custom styles to the list
    styles.concat(custom_styles)

    if options[:theme]
      style = options[:theme]
      # Test if provided value is valid
      unless styles.include?(style)
        puts "[!] Invalid highlight style: #{style}"
        exit 1
      end
    else
      # Choose syntax highlight style
      style = 'dracula'
      puts "[+] Choose syntax highlight style [#{style}]:"
    
      styles.each_with_index do |s, i|
        puts "#{colors[:red]}#{i}. #{s}#{colors[:nocolor]}"
      end
      puts_prompt
      choice = gets.chomp
      style = styles[choice.to_i] unless choice.empty?
    end
    
    # If custom style, set full path
    if custom_styles.include?(style)
      style = "#{Dir.home}/.local/share/pandoc/highlights/#{style}.theme"
    end

    if options[:input]
      input = options[:input]
    else
      puts_prompt '[+] Enter the file path where is your markdown report:'
      input = gets.chomp
    end

    if options[:output]
      output = options[:output]
    else
      puts_prompt '[+] Enter the path where you want to store the PDF report:'
      output = gets.chomp
    end

    if options[:exam]
      exam = options[:exam]
    elsif !options[:no_osid]
      puts '[+] Choose a Certification:'
      certifications.each_with_index do |c, i|
        puts "#{colors[:red]}#{i}. #{c[:exam]}#{colors[:nocolor]}"
      end
      puts_prompt
      cert = certifications[gets.chomp.to_i]
      exam = cert[:exam]
    end

    if options[:no_osid]
      puts '[+] Skipping OSID...'
    elsif options[:osid]
      osid = options[:osid]
    else
      puts '[+] Enter your OS ID:'
      print '> OS-'
      osid = "OS-#{gets.chomp}"
    end


    # Generating report
    puts '[+] Generating report...'
    pdf = options[:no_osid] ? "#{output}/Report.pdf" : "#{output}/#{exam}-#{osid}-Exam-Report.pdf"
    `pandoc #{input.shellescape} -o #{pdf.shellescape} \
      --from markdown+yaml_metadata_block+raw_html \
      --template eisvogel \
      --table-of-contents \
      --list-of-figures \
      --toc-depth 6 \
      --number-sections \
      --top-level-division=chapter \
      --highlight-style #{style} \
      --filter pandoc-crossref \
      --resource-path=.:/usr/share/osert/src:src \
      --resource-path=#{options[:'resource-path'].shellescape}
    `
    puts "[+] PDF generated at #{colors[:red]}#{pdf}#{colors[:nocolor]}"

    # Preview
    unless options[:no_preview]
      choice = 'n'
      unless options[:preview]
        puts_prompt '[+] Do you want to preview the report? [Y/n]'
        choice = gets.chomp
      end
      if options[:preview] || choice.downcase == 'y' || choice.empty?
        viewer = fork do
          exec "open #{pdf.shellescape}"
        end
        Process.detach(viewer)
      end
    end

    # Generating archive
    puts '[+] Generating archive...'
    archive = options[:no_osid] ? "#{output}/Report.7z" : "#{output}/#{exam}-#{osid}-Exam-Report.7z"
    `7z a #{archive.shellescape} #{File.expand_path(pdf.shellescape)}`

    # Optional lab report
    unless options[:no_labreport]
      puts_prompt '[+] Do you want to add an external lab report? [Y/n]'
      choice = gets.chomp
      if choice.downcase == 'y' || choice.empty?
        puts_prompt '[+] Write the path of your lab PDF:'
        lab = gets.chomp
        puts '[+] Updating archive...'
        `7z a #{archive.shellescape} #{File.expand_path(lab.shellescape)}`
      end
    end

    puts "[+] Archive generated at #{colors[:red]}#{archive}#{colors[:nocolor]}"

    # Calculate MD5
    puts '[+] Calculating MD5 of the archive...'
    require 'digest'
    md5 = Digest::MD5.hexdigest File.read(archive)
    puts "[+] Archive MD5 (upload integrity check): #{colors[:red]}#{md5}#{colors[:nocolor]}"
  end
rescue Errno::ENOENT => e
  puts e.message
  abort(subcommands[command].help)
end
