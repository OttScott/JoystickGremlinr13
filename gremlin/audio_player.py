# -*- coding: utf-8; -*-

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

from PySide6 import QtCore
from PySide6.QtCore import QUrl
from PySide6.QtMultimedia import QAudioOutput, QMediaPlayer

from gremlin.common import SingletonDecorator
from gremlin.config import Configuration
from gremlin.util import clamp


class PlayListItem:

    def __init__(self, sound_file: str, play_volume: int) -> None:
        self.sound_file = sound_file
        self.play_volume = play_volume


@SingletonDecorator
class AudioPlayer(QtCore.QObject):

    """Manages the playing of audio files."""

    def __init__(self, parent=None) -> None:
        super().__init__(parent)

        self.play_list: list[PlayListItem] = []
        self.player_output = QAudioOutput()

        self.player = QMediaPlayer()
        self.player.mediaStatusChanged.connect(self._media_status_changed)
        self.player.setAudioOutput(self.player_output)

    def play(self, sound_filename: str, volume: int) -> None:
        """Plays the given sound with the specified volume.

        Args:
            sound_filename: The filename of the sound file to play.
            volume: The volume of the playback, the value is in the range
                [0, 100] with 0 being mute and 100 maximum
        """
        sequential_play = Configuration().value(
            "action", "play-sound", "sequential-play"
        )
        is_playing = self.player.playbackState() != QMediaPlayer.StoppedState
        if sequential_play and is_playing:
            self.play_list.append(PlayListItem(sound_filename, volume))
            return
        else:
            self.play_list.clear()

        self._play(sound_filename, int(clamp(volume, 0.0, 100.0)))

    def stop(self) -> None:
        if self.player.playbackState() != QMediaPlayer.PlaybackState.StoppedState:
            self.player.stop()

    def _play(self, sound_filename: str, volume: int) -> None:
        self.player.setSource(QUrl.fromLocalFile(sound_filename))
        self.player_output.setVolume(volume / 100.0)
        self.player.play()

    def _media_status_changed(self, status: QMediaPlayer.MediaStatus) -> None:
        if status != QMediaPlayer.MediaStatus.EndOfMedia:
            return

        sequential_play = Configuration().value(
            "action", "play-sound", "sequential-play"
        )

        if len(self.play_list) > 0 and sequential_play:
            playlist_item = self.play_list.pop()
            self._play(playlist_item.sound_file, playlist_item.play_volume)
