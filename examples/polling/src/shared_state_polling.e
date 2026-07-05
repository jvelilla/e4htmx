note
    description: "Shared state for the polling example stored in a file"
class
    SHARED_STATE_POLLING

feature -- State File Operations

    state_file_path: STRING = "polling_state.txt"

    team1: STRING = "Chiefs"
    team2: STRING = "49ers"

    team1_has_ball: BOOLEAN
    score1: INTEGER
    score2: INTEGER
    percent_complete: REAL_64

    load_state
            -- Load state from file or set defaults
        local
            f: PLAIN_TEXT_FILE
        do
            create f.make_with_name (state_file_path)
            if f.exists and then f.is_readable then
                f.open_read
                
                f.read_line
                if f.last_string.is_boolean then
                    team1_has_ball := f.last_string.to_boolean
                end
                
                f.read_line
                if f.last_string.is_integer then
                    score1 := f.last_string.to_integer
                end
                
                f.read_line
                if f.last_string.is_integer then
                    score2 := f.last_string.to_integer
                end
                
                f.read_line
                if f.last_string.is_double then
                    percent_complete := f.last_string.to_double
                end
                
                f.close
            else
                team1_has_ball := True
                score1 := 0
                score2 := 0
                percent_complete := 0.0
            end
        end

    save_state
            -- Save state to file
        local
            f: PLAIN_TEXT_FILE
        do
            create f.make_with_name (state_file_path)
            f.open_write
            f.put_string (team1_has_ball.out)
            f.put_character ('%N')
            f.put_integer (score1)
            f.put_character ('%N')
            f.put_integer (score2)
            f.put_character ('%N')
            f.put_double (percent_complete)
            f.put_character ('%N')
            f.close
        end

    set_team1_has_ball (v: BOOLEAN)
        do team1_has_ball := v end
        
    set_score1 (v: INTEGER)
        do score1 := v end
        
    set_score2 (v: INTEGER)
        do score2 := v end
        
    set_percent_complete (v: REAL_64)
        do percent_complete := v end
        
end
