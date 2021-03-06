# ~*~ encoding: utf-8 ~*~
require 'cgi'
require 'sinatra'
require 'mustache/sinatra'
require "sinatra/reloader"
require 'jekyll'
require 'json'
require 'grit'
require 'stringex'

require 'pagoda/views/layout'
require 'pagoda/helper'
require 'pagoda/config'
require 'pagoda/jekyll-mod'

# Sinatra based frontend
module Shwedagon
  class App < Sinatra::Base

    # Create a new post from scratch. Return filename
    # This would not commit the file.
    def create_new_post(params)      
      post_title = params['post']['title']
      post_date  = (Time.now).strftime("%Y-%m-%d")
      yaml_data  = { 'title' => post_title,
        'layout' => 'post',
        'published' => false }

      content    = yaml_data.to_yaml + "---\n" + params[:post][:content]
      post_file  = (post_date + " " + post_title).to_url + '.md'
      file       = File.join(jekyll_site.source, *%w[_posts], post_file)
      File.open(file, 'w') { |file| file.write(content)}
      post_file
    end


    # Merge existing yaml with post params
    def merge_config(yaml, params)
      yaml['published'] = !(params[:post].has_key? 'draft' and
        params[:post]['draft'] == 'on')
      yaml['title']     = params[:post][:title]

      yaml
    end

    def write_post_contents(content, yaml, post_file)
      writeable_content  = yaml.to_yaml + "---\n" + content
      file_path          = post_path(post_file)

      if File.exists? file_path
        File.open(file_path, 'w') { |file| file.write(writeable_content)}
      end
    end

    # Update exiting post.
    def update_post(params)
      post_file   = params[:post][:name]
      post        = jekyll_post(post_file)
      yaml_config = merge_config(post.data, params)
      write_post_contents(params[:post][:content], yaml_config, post_file)

      post_file
    end

    # Index of drafts and published posts
    get '/' do
      @drafts    = posts_template_data(jekyll_site.read_drafts)
      @published = posts_template_data(jekyll_site.posts)

      mustache :home
    end


    #Delete any post. Ideally should be post. For convenience, it is get. 
    get '/delete/*' do
      post_file = params[:splat].first
      full_path = post_path(post_file)

      repo.remove([full_path])
      data = repo.commit_index "Deleted #{post_file}"
      
      redirect "/"
    end

    # Edit any post
    get '/edit/*' do
      post_file = params[:splat].first

      if not post_exists?(post_file)
        halt(404)
      end

      post     = jekyll_post(post_file) 
      @title   = post.data['title']
      @content = post.content
      @name    = post.name
      if post.data['published'] == false
        @draft = true
      end


      mustache :edit
    end

    get '/new' do
      @ptitle = params['ptitle']
      mustache :new_post
    end

    get '/settings' do
      mustache :settings
    end

    get '/settings/pull' do
      
      data = repo.git.pull({}, "origin", "master")
      return data + " done"
    end

    get '/settings/push' do
      data = repo.git.push
      return data + " done"
    end

    post '/save-post' do
      config = Jekyll.configuration({'source' => settings.blog})
      site   = Jekyll::Site.new(config)

      if params[:method] == 'put'
        filename = create_new_post(params)        
        log_message = "Created #{filename}"
      else
        filename = update_post(params)
        log_message = "Changed #{filename}"
      end

      # Stage the file for commit
      repo.add File.join(jekyll_site.source, *%w[_posts], filename)

      data = repo.commit_index log_message

      if params[:ajax]
        {:status => 'OK'}.to_json
      else
        redirect '/edit/' + filename
      end
    end

  end
end