# class PayerPillsChannel < ApplicationCable::Channel
#   def subscribed
#     # stream_from "some_channel"
#     bill = Bill.find(params[:id])
#     stream_for bill
#   end

#   def unsubscribed
#     # Any cleanup needed when channel is unsubscribed
#   end
# end
