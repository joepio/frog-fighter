"""Real-process GameNight lifecycle and authoritative controller routing."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import tempfile
import threading
import time
from host import Host, wait


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', required=True)
    parser.add_argument('--packed', action='store_true')
    args = parser.parse_args()
    host = Host()
    stop = threading.Event()
    project = Path(__file__).resolve().parents[1]
    executable = args.godot.replace('_console.exe', '.exe')
    child = None
    with tempfile.TemporaryDirectory(prefix='frog-integration-') as temporary:
        probe = Path(temporary) / 'probe.json'
        env = dict(os.environ, GAMENIGHT='1', GAMENIGHT_GAME_ID='frog-fighter',
                   GAMENIGHT_TOKEN='frog-test-token', GAMENIGHT_ADDR=f'127.0.0.1:{host.port}',
                   FROG_PROBE_PATH=str(probe))
        with open(Path(temporary) / 'game.log', 'w+') as log:
            try:
                command = [executable, '--headless']
                if not args.packed:
                    command += ['--path', str(project)]
                child = subprocess.Popen(command, env=env, stdout=log, stderr=log)
                host.connect()
                messages = wait(lambda: host.messages, lambda ms: any(m['type'] == 'hello' for m in ms))
                hello = next(m for m in messages if m['type'] == 'hello')
                assert hello['game'] == 'frog-fighter' and hello['token'] == 'frog-test-token'
                host.send('welcome', protocol_version=1, party={})
                host.send('setting_changed', key='mode', value='versus')
                host.send('setting_changed', key='lives', value=7)
                seats = [dict(index=i, occupant=dict(kind='local', player_id=f'p{i}'), controller=token)
                         for i, token in [(0, 'ordinal:7'), (2, 'ordinal:2')]]
                players = [dict(id='p0', name='Fern', color='#88bb55'), dict(id='p2', name='Poppy', color='#ee7766')]
                session = 'frog-one'
                host.send('prepare', game='frog-fighter', session=session, seats=seats, players=players)
                def read():
                    return wait(lambda: json.loads(probe.read_text()), lambda s: isinstance(s, dict), timeout=2)
                ready = wait(read, lambda s: s['phase'] == 'ready')
                assert ready['clock'] == 0 and ready['muted'] and not ready['running']
                assert [p['controller'] for p in ready['players']] == ['ordinal:7', 'ordinal:2']
                assert all(p['lives'] == 7 for p in ready['players']), ready
                host.send('setting_changed', key='lives', value=5)
                time.sleep(.2)
                assert all(p['lives'] == 7 for p in read()['players']), 'Changing lives must wait for the next round'
                assert len(ready['players']) == 2, 'Empty seats must not create frogs'
                host.send('start', session='wrong-session')
                time.sleep(.1)
                assert not read()['running']
                frames = [dict(controller='ordinal:2', axes=[32767,0,0,0,0,0], buttons=0),
                          dict(controller='ordinal:7', axes=[-32767,0,0,0,0,0], buttons=0)]
                def stream():
                    while not stop.wait(.025):
                        try:
                            host.send('controller_frame', controllers=frames)
                        except OSError:
                            return
                threading.Thread(target=stream, daemon=True).start()
                host.send('start', session=session)
                active = wait(read, lambda s: s['clock'] > .2)
                assert active['players'][0]['x'] < -10 and active['players'][1]['x'] > 10, active
                host.send('pause', session=session)
                paused = wait(read, lambda s: s['phase'] == 'paused')
                time.sleep(.3)
                assert read()['clock'] == paused['clock'] and read()['muted']
                assert not read()['running']
                players[0]['name'] = 'Fern Updated'
                host.send('party_updated', session=session, seats=seats, players=list(reversed(players)), presence=[])
                updated = wait(read, lambda s: s['players'][0]['name'] == 'Fern Updated')
                assert updated['players'][1]['name'] == 'Poppy' and updated['clock'] == paused['clock']
                frames[0]['axes'][0] = frames[1]['axes'][0] = 0
                host.send('resume', session=session)
                wait(read, lambda s: s['clock'] > paused['clock'] + .1)
                stop.set()
                time.sleep(1.3)
                for _ in range(15):
                    host.send('controller_frame', controllers=[dict(controller='ordinal:7', axes=[0]*6, buttons=64)])
                    time.sleep(.03)
                assert sum(m['type'] == 'request_overlay' for m in host.messages) == 1
                host.send('dispose', session=session)
                disposed = wait(read, lambda s: s['phase'] == 'idle')
                assert disposed['players'] == [] and not disposed['running'] and disposed['muted']
                host.send('prepare', game='frog-fighter', session='frog-two', seats=seats, players=players)
                ready_two = wait(read, lambda s: s['phase'] == 'ready' and s['session'] == 'frog-two')
                assert all(p['lives'] == 5 for p in ready_two['players']), ready_two
                host.close()
                child.wait(timeout=8)
                assert child.returncode == 0
                log.flush(); log.seek(0)
                output = log.read()
                assert 'SCRIPT ERROR' not in output and 'ERROR:' not in output, output
                print('PASS authentication, ready, sparse seats, reversed input order, session guards, pause/resume, profile ownership, Back gate, dispose/reprepare, disconnect')
            except BaseException:
                log.flush(); log.seek(0)
                print(log.read())
                raise
            finally:
                stop.set()
                if child and child.poll() is None:
                    child.terminate()
                    child.wait(timeout=5)


if __name__ == '__main__':
    main()
