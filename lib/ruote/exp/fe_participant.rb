#--
# Copyright (c) 2005-2009, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++


require 'ruote/exp/flowexpression'
require 'ruote/exp/condition'


module Ruote

  class ParticipantExpression < FlowExpression

    #include FilterMixin
      # TODO

    attr_reader :participant_name

    names :participant

    def apply

      @participant_name = attribute(:ref) || attribute_text

      @participant_name = @participant_name.to_s

      raise (
        ArgumentError.new("no participant name specified")
      ) if @participant_name == ''

      participant = plist.lookup(@participant_name)

      raise(
        ArgumentError.new("no participant named #{@participant_name.inspect}")
      ) unless participant

      @applied_workitem.participant_name = @participant_name

      persist

      dispatch_to(participant)
    end

    #def reply (workitem)
    #end

    def cancel

      participant = plist.lookup(@participant_name)

      participant.cancel(@fei)

      reply_to_parent(@applied_workitem)
    end

    protected

    def dispatch_to (participant)

      if participant.respond_to?(:do_not_thread) and participant.do_not_thread

        do_dispatch(participant)

      else

        Thread.new do
          begin
            do_dispatch(participant)
          rescue Exception => e
            pool.send(
              :handle_exception,
              :apply,
              { :fei => @fei, :workitem => @applied_workitem },
              e)
          end
        end
      end
    end

    def do_dispatch (participant)

      participant.consume(@applied_workitem)

      wqueue.emit(
        :workitems, :dispatched,
        :workitem => @applied_workitem, :pname => @participant_name)
    end
  end
end
