require 'gosu'

module ZOrder
    BACKGROUND, MIDDLE, TOP = *0..2
end

module Genre
    ALL, SHOEGAZER, INDIE, COMEDY, ROCK = 0..4
end

$genre_names = ['All', 'Shoegazer', 'Indie', 'Comedy', 'Rock']

class Album
    attr_accessor :title, :artist, :cover, :spine, :genre, :tracks

    def initialize (title, artist, cover, spine, genre, tracks)
        @title = title
        @artist = artist
        @cover = cover
        @spine = spine
        @genre = genre
        @tracks = tracks
    end
end

class Track
    attr_accessor :name, :location, :file

    def initialize (name, location, file)
        @name = name
        @location = location
        @file = file
    end
end

WIN_WIDTH = 640
WIN_HEIGHT = 400

class DemoWindow < Gosu::Window

    def initialize()
        super(WIN_WIDTH, WIN_HEIGHT, false)
        self.caption = "GUI Music Player"
        @font = Gosu::Font.new(20)
        @albums = create_album_file()
        @song = nil
        @play = Gosu::Image.new("Buttons/play.png")
        @pause = Gosu::Image.new("Buttons/pause.png")
        @skip = Gosu::Image.new("Buttons/skip.png")
        @stop = Gosu::Image.new("Buttons/stop.png")
        @next = Gosu::Image.new("Buttons/next.png")
        @play_next_png = Gosu::Image.new("Buttons/play next.png")
        @add_to_q = Gosu::Image.new("Buttons/add_to_q.png")
        @album_choice = nil
        @track_choice = nil
        @gallery = true
        @spine_x_loc = 50
        @sort_by = 0
        @current_albums = @albums
        @song_over = true
        @paused = false
        @upcoming = Array.new()
    end

    def draw()
        Gosu.draw_rect(0, 0, WIN_WIDTH, WIN_HEIGHT, Gosu::Color.argb(0xff_333f48), ZOrder::BACKGROUND, mode=:default)
        
        if @gallery
            #draw album covers
            i = 0
            x_loc = 0
            while i < @current_albums.length
                if mouse_over_spine(mouse_x, mouse_y) == i
                    @current_albums[i].spine.draw(@spine_x_loc + (x_loc * 40), 40, ZOrder::MIDDLE, 0.55, 0.55)
                else
                    @current_albums[i].spine.draw(@spine_x_loc + (x_loc * 40), 40, ZOrder::MIDDLE, 0.5, 0.5)
                end 
                x_loc += 1
                i += 1   
            end

            #buttons for the scrolling through library
            @next.draw(580, 160, ZOrder::TOP, 1.0, 1.0)
            @next.draw_rot(2, 160, ZOrder::TOP, 180, 1.0, 1.0)

            #'sort by:' text.
            for i in 0..$genre_names.length
                if mouse_over_sort(mouse_x, mouse_y) == i
                    @font.draw_text_rel($genre_names[i], 20 + 100 * i, 20, ZOrder::TOP, 0.5, 0.5, 0.8, 0.8, Gosu::Color.argb(0xff_7956ac))
                else
                    @font.draw_text_rel($genre_names[i], 20 + 100 * i, 20, ZOrder::TOP, 0.5, 0.5, 0.8, 0.8, Gosu::Color.argb(0xff_ced7dd))
                end
            end
            
        else
            @albums[@album_choice].cover.draw(50, 50, ZOrder::TOP, 0.5, 0.5)
            if mouse_over_button(mouse_x, mouse_y) == 4
                @font.draw_text("Return to Collection", 10, 10, ZOrder::TOP, 0.8, 0.8, Gosu::Color.argb(0xff_7956ac))
            else
                @font.draw_text("Return to Collection", 10, 10, ZOrder::TOP, 0.8, 0.8, Gosu::Color.argb(0xff_ced7dd))
            end 
            y_loc = 60
            i = 0
            while i < @albums[@album_choice].tracks.length
                if @albums[@album_choice].tracks[i].name.length > 23
                    if mouse_over_track(mouse_x, mouse_y) == i
                        @font.draw_text(@albums[@album_choice].tracks[i].name[0..20] + "...", 300, y_loc, ZOrder::TOP, 1.0, 1.0, Gosu::Color.argb(0xff_7956ac))
                    else
                        @font.draw_text(@albums[@album_choice].tracks[i].name[0..20] + "...", 300, y_loc, ZOrder::TOP, 1.0, 1.0, Gosu::Color.argb(0xff_ced7dd))
                    end
                else
                    if mouse_over_track(mouse_x, mouse_y) == i
                        @font.draw_text(@albums[@album_choice].tracks[i].name, 300, y_loc, ZOrder::TOP, 1.0, 1.0, Gosu::Color.argb(0xff_7956ac))
                    else
                        @font.draw_text(@albums[@album_choice].tracks[i].name, 300, y_loc, ZOrder::TOP, 1.0, 1.0, Gosu::Color.argb(0xff_ced7dd))
                    end
                end
                @play_next_png.draw(550, y_loc - 2, ZOrder::TOP, 0.4, 0.4)
                @add_to_q.draw(590, y_loc - 2, ZOrder::TOP, 0.4, 0.4)
                y_loc += 20
                i += 1
            end

        end

        if @song
            Gosu.draw_rect(0, WIN_HEIGHT - 50, WIN_WIDTH, 50, Gosu::Color.argb(0xff_353333), ZOrder::MIDDLE, mode=:default)
            @skip.draw(368, 348, ZOrder::TOP, 1, 1)
            @stop.draw(222, 348, ZOrder::TOP, 1, 1)
            @font.draw_text("Now Playing:", 20, 359, ZOrder::TOP, 0.8, 0.8, Gosu::Color.argb(0xff_ced7dd))
            if  @upcoming[@track_choice].name.length < 23
                @font.draw_text(@upcoming[@track_choice].name, 20, 378, ZOrder::TOP, 0.8, 0.8, Gosu::Color.argb(0xff_ced7dd))
            else
                @font.draw_text(@upcoming[@track_choice].name[0..20] + "...", 20, 378, ZOrder::TOP, 0.8, 0.8, Gosu::Color.argb(0xff_ced7dd))
            end
            @font.draw_text_rel("Up Next:", 620, 359, ZOrder::TOP, 1.0, 0, 0.8, 0.8, Gosu::Color.argb(0xff_ced7dd))
            next_track = (@track_choice + 1) % @upcoming.length
            if  @upcoming[next_track].name.length < 23
                @font.draw_text_rel(@upcoming[next_track].name, 620, 378, ZOrder::TOP, 1.0, 0, 0.8, 0.8, Gosu::Color.argb(0xff_ced7dd))
            else
                @font.draw_text_rel(@upcoming[next_track].name[0..20] + "...", 620, 378, ZOrder::TOP, 1.0, 0, 0.8, 0.8, Gosu::Color.argb(0xff_ced7dd))
            end
            if @song.playing?
                @pause.draw(294, 348, ZOrder::TOP, 1, 1)
            else
                @play.draw(294, 348, ZOrder::TOP, 1, 1)

            end
                
        end

    end


    def mouse_over_button(mouse_x, mouse_y)
        if mouse_x.between?(294, 346) && mouse_y.between?(348, 400)
            return 1 #pause/play button
        elsif mouse_x.between?(368, 420) && mouse_y.between?(348, 400)
            return 2 #skip button
        elsif mouse_x.between?(222, 274) && mouse_y.between?(348, 400)
            return 3 #stop button
        elsif mouse_x.between?(10, 135) && mouse_y.between?(10, 20)
            return 4 #return to menu button
        elsif mouse_x.between?(580, 632) && mouse_y.between?(160, 212)
            return 5 #scroll albums button
        elsif mouse_x.between?(2, 54) && mouse_y.between?(160, 212)
            return 6
        end
    end

    def mouse_over_sort(mouse_x, mouse_y)
        if @gallery
            count = $genre_names.length
            for i in 0..count - 1 do
                if mouse_x.between?((20 + 100 * i) - (($genre_names[i].length * 10) / 2), (20 + 100 * i) + (($genre_names[i].length * 10) / 2)) && mouse_y.between?(17.5, 27.5)
                    return i 
                end
            end
            return nil
        end
    end


    def mouse_over_spine(mouse_x, mouse_y)
        count = @current_albums.length
        for i in 0..count - 1 do
            if mouse_x.between?((@spine_x_loc + (40 * i)), (@spine_x_loc + 36 + (40 * i))) && mouse_y.between?(40, 322.5)
                #40 is the accumalative beginning x co-ord. 36 is the number of pixels of the png.
                return i
            end
        end
        return nil
    end

    def current_to_all(current_index)
        for i in 0..@albums.length - 1
            if @albums[i] == @current_albums[current_index]
                return i
            end
        end
        return nil
    end
    


    def mouse_over_track(mouse_x, mouse_y)
        if @album_choice && @gallery == false
            count = @albums[@album_choice].tracks.length - 1
            for i in 0..count do
                if mouse_x.between?(300, WIN_WIDTH) && mouse_y.between?((60 + (i * 20)), (80 + (i * 20)))
                    return i
                end
            end
            return nil
        end
    end

    def mouse_over_add(mouse_x, mouse_y)
        if mouse_x.between?(550, 570.8) && mouse_y.between?(0, WIN_HEIGHT)
            return 1
            #add to next
        elsif
            mouse_x.between?(590, 610.8) && mouse_y.between?(0, WIN_HEIGHT)
            return 2
            #add to queue
        end
    end

    def button_down(id)
        case id 
        when Gosu::MsLeft
            if mouse_over_track(mouse_x, mouse_y) && @gallery == false && !mouse_over_add(mouse_x, mouse_y)
                @upcoming = Array.new()
                @track_choice = mouse_over_track(mouse_x, mouse_y)
                for i in 0..@albums[@album_choice].tracks.length - 1
                    @upcoming << @albums[@album_choice].tracks[i]
                end
                @song = @upcoming[@track_choice].file
                @song.play(false)
            elsif mouse_over_add(mouse_x, mouse_y) == 1 && mouse_over_track(mouse_x, mouse_y)
                track_index = mouse_over_track(mouse_x, mouse_y)
                song_to_add = @albums[@album_choice].tracks[track_index]
                if @upcoming.length == 0
                    @upcoming << song_to_add
                    @track_choice = 0
                    @song = @upcoming[@track_choice].file
                    @song.play
                else 
                    @upcoming.insert(@track_choice + 1, song_to_add)
                end
            elsif mouse_over_add(mouse_x, mouse_y) == 2 && mouse_over_track(mouse_x, mouse_y)
                track_index = mouse_over_track(mouse_x, mouse_y)
                song_to_add = @albums[@album_choice].tracks[track_index]
                @upcoming << song_to_add
                if !@song
                    @track_choice = 0
                    @song = @upcoming[@track_choice].file
                    @song.play
                end
            elsif mouse_over_button(mouse_x, mouse_y) == 1
                if @song.playing?
                    @paused = true
                    @song.pause
                else
                    @paused = false
                    @song.play
                end
            elsif mouse_over_button(mouse_x, mouse_y) == 2
                next_track()
            elsif mouse_over_button(mouse_x, mouse_y) == 3
                @song_over = false
                @song.stop
            elsif mouse_over_spine(mouse_x, mouse_y) && @gallery && !mouse_over_button(mouse_x, mouse_y)
                current_index = mouse_over_spine(mouse_x, mouse_y)
                @album_choice = current_to_all(current_index)
                @gallery = false
            elsif mouse_over_button(mouse_x, mouse_y) == 4
                @gallery = true
            elsif mouse_over_button(mouse_x, mouse_y) == 5
                @spine_x_loc -= 5
            elsif mouse_over_button(mouse_x, mouse_y) == 6
                if @spine_x_loc < 50
                    @spine_x_loc += 5
                end
            elsif mouse_over_sort(mouse_x, mouse_y) && @gallery
                if mouse_over_sort(mouse_x, mouse_y) == 0
                    @current_albums = @albums
                else
                    sort_by = mouse_over_sort(mouse_x, mouse_y)
                    @current_albums = current_sort(sort_by)
                end
            end
        when Gosu::KbP
            @song.pause
        when Gosu::KbUp
            @song.volume += 0.1
        when Gosu::KbDown
            @song.volume -= 0.1
        end
    end
    def next_track()
        if @upcoming[@track_choice + 1]
            @track_choice += 1
        else
            @track_choice = 0
        end
        @song = @upcoming[@track_choice].file
        @song.play
    end

    def update()
        if @song && @song.playing?
            @song_over = true
        end
        if @song && !@song.playing? && @song_over && !@paused
            next_track()
        end
    end 


    def current_sort(sort_by)
        current_albums = Array.new()
        for i in 0..@albums.length - 1
            if @albums[i].genre == sort_by
                current_albums << @albums[i]
            end
        end
        return current_albums
    end


    def read_track(music_file)
        track_name = music_file.gets().chomp()
        track_location = music_file.gets().chomp()
        track_file = Gosu::Song.new(track_location)
        track_return = Track.new(track_name, track_location, track_file)
    end



    def read_tracks(music_file)
        tracks = Array.new()
        count = music_file.gets().to_i()

        for i in 0..(count - 1) do
            track = read_track(music_file)
            tracks << track
        end
        return tracks
    end

    def read_albums(music_file)

        # reads in all the Album's fields/attributes including all the tracks
        albums = Array.new()
        albums_length = music_file.gets().to_i()

        for i in 0..(albums_length - 1) do 
            album_artist = music_file.gets().chomp()
            album_title = music_file.gets().chomp()
            cover_location = music_file.gets().chomp()
            spine_location = music_file.gets().chomp()
            album_cover = Gosu::Image.new(cover_location)
            album_spine = Gosu::Image.new(spine_location)
            album_genre = music_file.gets().chomp().to_i
            tracks = read_tracks(music_file)
            album = Album.new(album_title, album_artist, album_cover, album_spine, album_genre, tracks)
            albums << album
        end
        return albums
    end

    def create_album_file()
        music_file = File.new("collection.txt", "r")
        albums = read_albums(music_file)
        music_file.close
        return albums
    end
    #create a current_playlist array. Insert tracks and album tracks into current_playist.




end

DemoWindow.new.show



