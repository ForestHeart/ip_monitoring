# Use the official Ruby image as a base image
FROM ruby:3.2

# Install dependencies
# iputils-ping need to do ping and ping6
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs iputils-ping

# Set environment variables for the database and Redis
ENV RACK_ENV=development

# Create and set the working directory
RUN mkdir /myapp
WORKDIR /myapp

# Add Gemfile and Gemfile.lock to install gems
COPY Gemfile /myapp/Gemfile
COPY Gemfile.lock /myapp/Gemfile.lock

# Install gems
RUN bundle install

# Copy the main application
COPY . /myapp

# Add a script to be executed every time the container starts.
COPY entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh

# Expose port 9292 for the app
EXPOSE 9292

# Start the main process.
ENTRYPOINT ["entrypoint.sh"]
