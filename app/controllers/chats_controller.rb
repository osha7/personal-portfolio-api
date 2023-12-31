class ChatsController < ApplicationController
  before_action :set_chat, only: %i[ show update destroy ]
  require "http"
  require "json"

  # GET /chats
  def index
    @chats = Chat.all

    render json: @chats
  end

  def find_by_token
    @chats_by_token = Chat.where({:encrypted_token => params["token"]})
    render json: @chats_by_token
  end

  # GET /chats/1
  def show
    render json: @chat
  end

  # POST /chats
  def create
    @chat = Chat.new(chat_params)
    # only assign a new token if not present - update this to send to FE and assign to user in local storage if necessary
    # if !@chat.encrypted_token
    #   @chat.encrypted_token = SecureRandom.hex(16)
    # end

    if @chat.save

      messages = [
        {
          "role" => "system", # system prompt (optional)
          "content" => "You are a helpful assistant who talks like you're from chicago, but never mentions sports."
        },
        {
          "role" => "#{@chat.role}",
          "content" => "#{@chat.content}"
        },
      ]

      relevent_chats = Chat.where({:encrypted_token => @chat.encrypted_token})

      relevent_chats.each do |chat|
        messages.push({"role" => chat.role, "content" => chat.content})
      end

      # ---Call to OpenAI-----------------------------------

      request_headers_hash = {
        "Authorization" => "Bearer #{ENV['OPEN_API_KEY']}",
        "content-type" => "application/json"
      }

      request_body_hash = {
        # "temperature" => ,
        "model" => "gpt-4",
        "messages" => messages
      }

      request_body_json = JSON.generate(request_body_hash)

      raw_response = HTTP.headers(request_headers_hash).post(
        "https://api.openai.com/v1/chat/completions",
        :body => request_body_json
      ).to_s

      parsed_response = JSON.parse(raw_response)

      chat = Chat.new({:role => "assistant", :content => parsed_response["choices"][0]["message"]["content"], :encrypted_token => @chat.encrypted_token})
      chat.save

      # ------------------------------------------------

      render json: @chat, status: :created, location: @chat
    else
      render json: @chat.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /chats/1
  def update
    if @chat.update(chat_params)
      render json: @chat
    else
      render json: @chat.errors, status: :unprocessable_entity
    end
  end

  # DELETE /chats/1
  def destroy
    @chat.destroy!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_chat
      @chat = Chat.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def chat_params
      params.require(:chat).permit(:role, :content, :encrypted_token)
    end
end
