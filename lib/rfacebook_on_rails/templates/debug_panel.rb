# Copyright (c) 2007, Matt Pizzimenti (www.livelearncode.com)
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
# 
# Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
# 
# Neither the name of the original author nor the names of contributors
# may be used to endorse or promote products derived from this software
# without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

module RFacebook
  module Rails
    DEBUG_PANEL_ERB_TEMPLATE = <<-end_info
                
<style type="text/css">

.RFacebook .environment
	{
		padding: 30px;
        
		background: #F7F7F7;
		border-bottom: 1px solid #B7B7B7;
	}

.RFacebook .environment a
	{
		color: #3F5A95;
	}

.RFacebook .environment table
	{
		margin: 0px auto 5px auto;
		width: 100%;
		
		border-collapse: collapse;
	}

.RFacebook .environment td
	{
		padding: 5px;
		padding-left: 10px;
		border-width: 1px 0px 1px 0px;
    
		border-color: #ccc;
		border-style: solid;
		font-size: 0.9em;
	}

.RFacebook .environment td.value
	{
		width: 100%;
    
		color: #777;
	}

.RFacebook .environment td.header
	{
		padding-top: 10px;
		padding-left: 0px;
		border-top-width: 0px;
		
		font-weight: bold;
		font-size: 1.3em;
	}

.RFacebook .environment h1
	{
		margin: 0px 0px 5px 0px;
		padding: 0px;
    
		color: #3F5A95;
		font-size: 1.6em;
	}

.RFacebook .environment p
	{
		padding: 5px;
		margin: 0px 0px 20px 0px;
    
		color: #777;
	}
  
.RFacebook .error
	{
		color: red;
		margin: 0px;
		padding: 2px;
		color: #FF9A8D;
		background-color: #900;
	}

.RFacebook .valid
	{
		margin: 0px;
		padding: 2px;
		color: #B2FE8C;
		background-color: #06B012;
	}

.RFacebook table.details
	{
		border-collapse: collapse;
		width: auto;
	}

.RFacebook table.details td
	{
		border: none;
		padding: 0px;
		color: #777;
	}

.RFacebook table.details td.value
	{
		width: 100%;
		padding-left: 10px;
		color: black;
	}

</style>

<div class="RFacebook">
	
	<div class="environment">
  
		<h1>RFacebook <span style="font-weight: normal; color: #777">environment information</span></h1>
		<p>
			This shows you at a glance the information that RFacebook has populated
			for you.
			<br/>
			More information at <a href="http://rfacebook.rubyforge.org">rfacebook.rubyforge.org</a>.
			Please report RFacebook bugs <a href="http://rubyforge.org/tracker/?func=add&group_id=3607&atid=13796">here</a>.
			
		</p>
  
		<table>
  
			<!-- ####################### ActionController ####################### -->
			<tr>
				<td colspan="3" class="header"><%= self.class %></td>
			</tr>
			
			<% facebook_status_manager.each_status_check do |statusCheck| %>
				<tr>
					<td class="title"><%= statusCheck.title %></td>
					<td class="rstatus">
						<% if statusCheck.valid? %>
							<span class="valid">OK</span>
						<% else %>
							<span class="error">PROBLEM</span>
						<% end %>
					</td>
					<td class="value">
						<% if statusCheck.message.class == String %>
							<%= statusCheck.message %>
						<% elsif statusCheck.message.class == Hash %>
							<table class="details">
								<% statusCheck.message.each do |k,v| %>
									<tr>
										<td><%= k %></td>
										<td class="value"><%= v %></td>
									</tr>
								<% end %>
							</table>
						<% end %>
					</td>
				</tr>
			<% end %>
		
		
		</table>
  
	</div>
</div>        













end_info

  end
end