class StaticController < ApplicationController
    def home
        render :json => {:status => "Up and running!"}
    end
end