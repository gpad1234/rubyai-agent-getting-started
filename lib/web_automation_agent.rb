# frozen_string_literal: true

require 'mechanize'
require 'anthropic'

# Web automation agent using Mechanize for web scraping and interaction
class WebAutomationAgent
  def initialize(client)
    @client = client
    @mechanize = Mechanize.new do |agent|
      agent.user_agent_alias = 'Mac Safari'
      agent.follow_meta_refresh = true
    end
  end

  # Scrape and analyze a webpage
  def scrape_and_analyze(url, analysis_prompt = "Summarize the main content of this page")
    puts "\n🌐 Scraping URL: #{url}"
    
    page = @mechanize.get(url)
    
    # Extract text content
    content = page.search('p, h1, h2, h3').map(&:text).join("\n")
    
    puts "📄 Extracted #{content.length} characters of content"
    
    # Analyze with Claude
    analyze_content(content, analysis_prompt)
  end

  # Extract links and analyze them
  def extract_and_analyze_links(url, max_links = 5)
    puts "\n🔗 Extracting links from: #{url}"
    
    page = @mechanize.get(url)
    links = page.links[0...max_links]
    
    link_data = links.map do |link|
      {
        text: link.text.strip,
        href: link.href,
        uri: link.uri&.to_s
      }
    end
    
    # Analyze links with Claude
    prompt = "Analyze these links and describe what type of website this appears to be:\n\n#{link_data.map { |l| "- #{l[:text]}: #{l[:uri]}" }.join("\n")}"
    
    analyze_content(prompt, "Provide insights about this website")
  end

  # Search and extract data
  def search_and_extract(url, search_selector, analysis_prompt)
    puts "\n🔍 Searching elements with selector: #{search_selector}"
    
    page = @mechanize.get(url)
    elements = page.search(search_selector)
    
    content = elements.map(&:text).join("\n")
    
    puts "📊 Found #{elements.size} matching elements"
    
    analyze_content(content, analysis_prompt)
  end

  # Form submission with AI-generated data
  def fill_and_submit_form(url, form_selector, field_requirements)
    puts "\n📝 Accessing form at: #{url}"
    
    page = @mechanize.get(url)
    form = page.forms.first
    
    unless form
      puts "❌ No form found on page"
      return nil
    end
    
    # Generate form data using Claude
    prompt = "Generate realistic data for a form with these fields: #{field_requirements.join(', ')}. Return as JSON."
    
    response = @client.messages(
      parameters: {
        model: 'claude-sonnet-4-20250514',
        max_tokens: 500,
        messages: [{ role: 'user', content: prompt }]
      }
    )
    
    ai_data = response.dig('content', 0, 'text')
    
    puts "🤖 AI generated form data"
    puts "⚠️  Note: Form submission is disabled in this example for safety"
    
    { form: form, ai_data: ai_data }
  end

  # Monitor page changes
  def monitor_page_changes(url, check_interval = 60, duration = 300)
    puts "\n👁️  Monitoring #{url} for changes..."
    
    initial_page = @mechanize.get(url)
    initial_content = initial_page.body
    
    changes = []
    end_time = Time.now + duration
    
    while Time.now < end_time
      sleep check_interval
      
      current_page = @mechanize.get(url)
      current_content = current_page.body
      
      if current_content != initial_content
        change = {
          timestamp: Time.now,
          size_diff: current_content.length - initial_content.length
        }
        changes << change
        
        puts "🔄 Change detected at #{change[:timestamp]}"
        
        # Analyze change with Claude
        analyze_content(
          "Previous size: #{initial_content.length}, New size: #{current_content.length}",
          "What might have changed on this webpage?"
        )
        
        initial_content = current_content
      end
    end
    
    changes
  end

  # Download and analyze document
  def download_and_analyze(url, doc_type = 'text')
    puts "\n⬇️  Downloading document from: #{url}"
    
    downloaded = @mechanize.get(url)
    
    case doc_type
    when 'text'
      content = downloaded.body
    when 'html'
      content = downloaded.search('body').text
    else
      content = downloaded.body
    end
    
    puts "📥 Downloaded #{content.length} characters"
    
    analyze_content(content, "Summarize this document")
  end

  private

  def analyze_content(content, prompt)
    puts "\n🤖 Analyzing content with Claude..."
    
    # Truncate content if too long
    truncated_content = content.length > 3000 ? content[0...3000] + "..." : content
    
    full_prompt = "#{prompt}\n\nContent:\n#{truncated_content}"
    
    response = @client.messages(
      parameters: {
        model: 'claude-3-5-haiku-20241022',
        max_tokens: 800,
        messages: [{ role: 'user', content: full_prompt }]
      }
    )
    
    result = response.dig('content', 0, 'text')
    
    puts "💬 Analysis result:"
    puts result
    puts ""
    
    {
      original_content_length: content.length,
      analysis: result,
      timestamp: Time.now
    }
  end
end
