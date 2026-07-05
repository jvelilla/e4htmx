note
    description: "WebSocket event handler for auto-reloading clients"

class
    RELOAD_WEBSOCKET_EVENT_HANDLER

inherit
    WEB_SOCKET_EVENT_I
        redefine
            on_timer
        end

create
    make

feature {NONE} -- Initialization

    make (a_www_dir: PATH)
        do
            www_dir := a_www_dir
            last_check_time := current_www_modified_time
        end

feature -- Access

    www_dir: PATH
            -- The directory being watched for changes.

    last_check_time: INTEGER
            -- The timestamp of the last modification seen.

feature -- Websocket Events

    on_open (ws: WEB_SOCKET)
        do
            set_timer_delay (1) -- Check every 1 second
            -- Send an initial connection success message for debugging if needed
            -- ws.send_text ("Connected to auto-reload server")
        end

    on_binary (ws: WEB_SOCKET; a_message: READABLE_STRING_8)
        do
            -- Ignore binary messages
        end

    on_text (ws: WEB_SOCKET; a_message: READABLE_STRING_8)
        do
            -- Ignore incoming text messages
        end

    on_close (ws: WEB_SOCKET)
        do
            -- Nothing to do
        end

    on_timer (ws: WEB_SOCKET)
        local
            l_current_time: INTEGER
        do
            l_current_time := current_www_modified_time
            if l_current_time > last_check_time then
                last_check_time := l_current_time
                ws.send_text ("reload")
            end
        end

feature {NONE} -- Implementation

    current_www_modified_time: INTEGER
            -- Gets the max modification time of any file in `www_dir`.
            -- For simplicity, we just check the directory's own modification time,
            -- or `index.html` modification time. A full recursive check is heavier in Eiffel.
        local
            f: RAW_FILE
        do
            create f.make_with_path (www_dir.extended ("index.html"))
            if f.exists then
                Result := f.date
            else
                Result := 0
            end
        end

end
