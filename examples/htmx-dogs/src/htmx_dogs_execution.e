note
	description: "Application execution router for HTMX Dogs."
	date: "$Date$"
	revision: "$Revision$"

class
	HTMX_DOGS_EXECUTION

inherit
	WSF_FILTERED_ROUTED_EXECUTION

	WSF_ROUTED_URI_TEMPLATE_HELPER

	WSF_ROUTED_URI_HELPER

	SHARED_EXECUTION_ENVIRONMENT

	SHARED_DOG_SERVICES

	EWF_GLIMMER_INTEGRATION

create
	make

feature {NONE} -- Initialization

feature -- Filter

	create_filter
			-- Create `filter'
		do
			create {WSF_MAINTENANCE_FILTER} filter
		end

	setup_filter
			-- Setup `filter'
		local
			f: like filter
		do
			create {WSF_CORS_FILTER} f
			f.set_next (create {WSF_LOGGING_FILTER})
			filter.append (f)
		end

feature -- Router

	setup_router
			-- Setup `router'
		local
			www: WSF_FILE_SYSTEM_HANDLER
		do
			router.handle ("/doc", create {WSF_ROUTER_SELF_DOCUMENTATION_HANDLER}.make (router), router.methods_GET)

			map_uri_agent ("/form", agent handle_form, router.methods_GET)
			map_uri_agent ("/table-rows", agent handle_table_rows, router.methods_GET)
			map_uri_agent ("/dog", agent handle_add_dog, router.methods_POST)
			map_uri_template_agent ("/select/{id}", agent handle_select_dog, router.methods_PUT)
			map_uri_template_agent ("/dog/{id}", agent handle_update_dog, router.methods_PUT)
			map_uri_agent ("/deselect", agent handle_deselect, router.methods_PUT)
			map_uri_template_agent ("/dog/{id}", agent handle_delete_dog, router.methods_DELETE)

			create www.make_with_path (document_root)
			www.set_directory_index (<<"index.html">>)
			www.set_not_found_handler (agent execute_not_found)
			router.handle ("", www, router.methods_GET)
		end

feature -- Configuration

	document_root: PATH
			-- Document root to look for files or directories
		once
			Result := execution_environment.current_working_path.extended ("www")
		end

feature -- Handlers

	handle_form (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle GET /form request, rendering either an Add or Edit form
		local
			l_template: GLM_HTML_TEMPLATE
			l_selected_id: detachable STRING_32
			l_dog: detachable DOG
			l_result: STRING_32
		do
			l_selected_id := selected_id_cell.item
			create l_template.make

			if attached l_selected_id as id and then shared_dogs.has (id) then
				l_dog := shared_dogs.item (id)
				if attached l_dog as dog then
					l_template.set_boolean ("is_editing", True)
					l_template.set_string ("selected_id", dog.id)
					l_template.set_string ("name", dog.name)
					l_template.set_string ("breed", dog.breed)
					l_template.set_string ("submit_label", "Update")
				end
			else
				l_template.set_boolean ("is_editing", False)
				l_template.set_string ("selected_id", "")
				l_template.set_string ("name", "")
				l_template.set_string ("breed", "")
				l_template.set_string ("submit_label", "Add")
			end

			l_result := l_template.render_file (document_root.appended ("\form.html").name)

			if l_template.has_error and then attached l_template.last_error as err then
				new_response_html (req, res, "<div class=%"error%">" + err.to_string_8 + "</div>")
			else
				new_response_html (req, res, l_result.to_string_8)
			end
		end

	handle_table_rows (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle GET /table-rows request, returning rows of dogs sorted by name
		local
			l_dogs: ARRAYED_LIST [DOG]
			l_sorter: SORTER [DOG]
			l_html: STRING
		do
			create l_dogs.make_from_iterable (shared_dogs.linear_representation)

			-- Create and apply quick sorter
			create {QUICK_SORTER [DOG]} l_sorter.make (
				create {AGENT_EQUALITY_TESTER [DOG]}.make (
					agent (a_dog1, a_dog2: DOG): BOOLEAN
						do
							Result := a_dog1.name < a_dog2.name
						end))
			l_sorter.sort (l_dogs)

			create l_html.make_empty
			across l_dogs as dog loop
				l_html.append (dog_row (dog.item, False))
			end

			new_response_html (req, res, l_html)
		end

	handle_add_dog (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle POST /dog request to create a new dog
		local
			l_name: detachable STRING_32
			l_breed: detachable STRING_32
			l_dog: DOG
			l_html: STRING
		do
			if
				attached {WSF_STRING} req.form_parameter ("name") as p_name and then
				attached {WSF_STRING} req.form_parameter ("breed") as p_breed
			then
				l_name := p_name.value
				l_breed := p_breed.value

				if not l_name.is_empty and then not l_breed.is_empty then
					l_dog := add_dog (l_name, l_breed)
					l_html := dog_row (l_dog, False)
					new_response_html_created (req, res, l_html)
				else
					res.set_status_code ({HTTP_STATUS_CODE}.bad_request)
					new_response_html (req, res, "<div class=%"error%">Name and breed cannot be empty.</div>")
				end
			else
				res.set_status_code ({HTTP_STATUS_CODE}.bad_request)
				new_response_html (req, res, "<div class=%"error%">Missing required form parameters.</div>")
			end
		end

	handle_select_dog (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle PUT /select/{id} request to select a dog for editing
		local
			l_id: STRING_32
		do
			if attached {WSF_STRING} req.path_parameter ("id") as p_id then
				l_id := p_id.value
				if shared_dogs.has (l_id) then
					selected_id_cell.put (l_id)
					new_response_empty_with_trigger (req, res, "selection-change")
				else
					res.set_status_code ({HTTP_STATUS_CODE}.not_found)
					res.put_string ("Dog not found")
				end
			else
				res.set_status_code ({HTTP_STATUS_CODE}.bad_request)
				res.put_string ("Missing ID parameter")
			end
		end

	handle_update_dog (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle PUT /dog/{id} request to update a dog's name/breed
		local
			l_id: STRING_32
			l_dog: detachable DOG
			l_name: detachable STRING_32
			l_breed: detachable STRING_32
			l_html: STRING
		do
			if attached {WSF_STRING} req.path_parameter ("id") as p_id then
				l_id := p_id.value
				if shared_dogs.has (l_id) then
					l_dog := shared_dogs.item (l_id)
					if
						attached l_dog as dog and then
						attached {WSF_STRING} req.form_parameter ("name") as p_name and then
						attached {WSF_STRING} req.form_parameter ("breed") as p_breed
					then
						l_name := p_name.value
						l_breed := p_breed.value

						if not l_name.is_empty and then not l_breed.is_empty then
							dog.set_name (l_name)
							dog.set_breed (l_breed)

							-- Reset selection
							selected_id_cell.put (Void)

							-- Generate row HTML with update mode (hx-swap-oob="true")
							l_html := dog_row (dog, True)
							new_response_html_with_trigger (req, res, l_html, "selection-change")
						else
							res.set_status_code ({HTTP_STATUS_CODE}.bad_request)
							new_response_html (req, res, "<div class=%"error%">Name and breed cannot be empty.</div>")
						end
					else
						res.set_status_code ({HTTP_STATUS_CODE}.bad_request)
						res.put_string ("Missing form parameters")
					end
				else
					res.set_status_code ({HTTP_STATUS_CODE}.not_found)
					res.put_string ("Dog not found")
				end
			else
				res.set_status_code ({HTTP_STATUS_CODE}.bad_request)
				res.put_string ("Missing ID parameter")
			end
		end

	handle_deselect (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle PUT /deselect to clear active selection
		do
			selected_id_cell.put (Void)
			new_response_empty_with_trigger (req, res, "selection-change")
		end

	handle_delete_dog (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle DELETE /dog/{id} to delete a dog
		local
			l_id: STRING_32
		do
			if attached {WSF_STRING} req.path_parameter ("id") as p_id then
				l_id := p_id.value
				if shared_dogs.has (l_id) then
					shared_dogs.remove (l_id)
					new_response_empty (req, res)
				else
					res.set_status_code ({HTTP_STATUS_CODE}.not_found)
					res.put_string ("Dog not found")
				end
			else
				res.set_status_code ({HTTP_STATUS_CODE}.bad_request)
				res.put_string ("Missing ID parameter")
			end
		end

feature {NONE} -- Implementation Helpers

	dog_row (a_dog: DOG; a_updating: BOOLEAN): STRING
			-- Generate HTML row for dog table
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING_32
		do
			create l_template.make
			l_template.set_variable ("dog", a_dog)
			l_template.set_boolean ("updating", a_updating)

			l_result := l_template.render ("[
				<tr class="on-hover" id="row-{dog.id}" {{if updating}}hx-swap-oob="true"{{end}}>
					<td>{dog.name}</td>
					<td>{dog.breed}</td>
					<td class="buttons">
						<button
							class="show-on-hover"
							hx-delete="/dog/{dog.id}"
							hx-confirm="Are you sure?"
							hx-target="closest tr"
							hx-swap="outerHTML"
							type="button"
						>✕</button>
						<button
							class="show-on-hover"
							hx-put="/select/{dog.id}"
							hx-swap="none"
							type="button"
						>Edit</button>
					</td>
				</tr>
			]")

			Result := l_result.to_string_8
		end

	new_response_html (req: WSF_REQUEST; res: WSF_RESPONSE; output: STRING)
			-- Send standard HTML response
		local
			h: HTTP_HEADER
		do
			create h.make
			h.put_content_type_text_html
			h.put_content_length (output.count)
			h.put_current_date
			res.set_status_code ({HTTP_STATUS_CODE}.ok)
			res.put_header_text (h.string)
			res.put_string (output)
		end

	new_response_html_created (req: WSF_REQUEST; res: WSF_RESPONSE; output: STRING)
			-- Send 201 Created HTML response
		local
			h: HTTP_HEADER
		do
			create h.make
			h.put_content_type_text_html
			h.put_content_length (output.count)
			h.put_current_date
			res.set_status_code ({HTTP_STATUS_CODE}.created)
			res.put_header_text (h.string)
			res.put_string (output)
		end

	new_response_html_with_trigger (req: WSF_REQUEST; res: WSF_RESPONSE; output: STRING; a_trigger: READABLE_STRING_8)
			-- Send HTML response with an HTMX trigger header
		local
			h: HTTP_HEADER
		do
			create h.make
			h.put_content_type_text_html
			h.put_content_length (output.count)
			h.put_current_date
			h.put_header_key_value ("HX-Trigger", a_trigger)
			res.set_status_code ({HTTP_STATUS_CODE}.ok)
			res.put_header_text (h.string)
			res.put_string (output)
		end

	new_response_empty_with_trigger (req: WSF_REQUEST; res: WSF_RESPONSE; a_trigger: READABLE_STRING_8)
			-- Send empty response with an HTMX trigger header
		local
			h: HTTP_HEADER
		do
			create h.make
			h.put_content_length (0)
			h.put_current_date
			h.put_header_key_value ("HX-Trigger", a_trigger)
			res.set_status_code ({HTTP_STATUS_CODE}.ok)
			res.put_header_text (h.string)
			res.put_string ("")
		end

	new_response_empty (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Send empty 200 response
		local
			h: HTTP_HEADER
		do
			create h.make
			h.put_content_length (0)
			h.put_current_date
			res.set_status_code ({HTTP_STATUS_CODE}.ok)
			res.put_header_text (h.string)
			res.put_string ("")
		end

	execute_not_found (uri: READABLE_STRING_8; req: WSF_REQUEST; res: WSF_RESPONSE)
			-- `uri' is not found, redirect to default page
		do
			res.redirect_now_with_content (req.script_url ("/"), uri + ": not found.%NRedirection to " + req.script_url ("/"), "text/html")
		end

end
