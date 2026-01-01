#!/usr/bin/env python3
"""
Simple API for managing VNC user containers
"""
import os
import subprocess
import json
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import parse_qs, urlparse

COMPOSE_DIR = "/app"
DEFAULT_PASSWORD = "idea123"

class APIHandler(BaseHTTPRequestHandler):
    def _send_json(self, data, status=200):
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def do_OPTIONS(self):
        self._send_json({})

    def do_GET(self):
        if self.path == '/api/users':
            users = self._get_users()
            self._send_json({'users': users})
        else:
            self._send_json({'error': 'Not found'}, 404)

    def do_POST(self):
        if self.path == '/api/users':
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length).decode()
            data = json.loads(body) if body else {}
            
            user_id = data.get('id', '')
            password = data.get('password', DEFAULT_PASSWORD)
            
            if not user_id:
                self._send_json({'error': 'Missing user id'}, 400)
                return
            
            result = self._create_user(user_id, password)
            if result['success']:
                self._send_json(result)
            else:
                self._send_json(result, 500)
        else:
            self._send_json({'error': 'Not found'}, 404)

    def do_DELETE(self):
        parsed = urlparse(self.path)
        if parsed.path.startswith('/api/users/'):
            user_id = parsed.path.split('/')[-1]
            
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length).decode()
            data = json.loads(body) if body else {}
            password = data.get('password', '')
            
            if not self._verify_password(user_id, password):
                self._send_json({'error': 'Invalid password'}, 403)
                return
            
            result = self._delete_user(user_id)
            if result['success']:
                self._send_json(result)
            else:
                self._send_json(result, 500)
        else:
            self._send_json({'error': 'Not found'}, 404)

    def _get_users(self):
        """Get list of running user containers"""
        try:
            result = subprocess.run(
                ['docker', 'ps', '--format', '{{.Names}}', '--filter', 'name=idea-user'],
                capture_output=True, text=True
            )
            containers = [name.replace('idea-', '') for name in result.stdout.strip().split('\n') if name]
            return containers
        except Exception as e:
            return []

    def _create_user(self, user_id, password):
        """Create a new user container"""
        try:
            # Generate docker-compose override for new user
            container_name = f"idea-{user_id}"
            
            # Check if already exists
            result = subprocess.run(
                ['docker', 'ps', '-a', '--format', '{{.Names}}', '--filter', f'name={container_name}'],
                capture_output=True, text=True
            )
            if container_name in result.stdout:
                return {'success': False, 'error': 'User already exists'}
            
            # Build and run new container
            env = os.environ.copy()
            env['VNC_PASSWORD'] = password
            
            # Use docker run directly
            cmd = [
                'docker', 'run', '-d',
                '--name', container_name,
                '--hostname', container_name,
                '-e', f'VNC_PASSWORD={password}',
                '-e', 'TZ=Asia/Shanghai',
                '-v', 'idea-docker-vnc_shared-projects:/home/developer/projects',
                '-v', f'idea-config-{user_id}:/home/developer/.config',
                '-v', f'idea-cache-{user_id}:/home/developer/.cache',
                '-v', f'idea-local-{user_id}:/home/developer/.local',
                '--shm-size', '2gb',
                '--network', 'idea-docker-vnc_default',
                '--restart', 'unless-stopped',
                'idea-docker-vnc-idea-user1'  # Use existing image
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode != 0:
                return {'success': False, 'error': result.stderr}
            
            return {'success': True, 'message': f'User {user_id} created'}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def _delete_user(self, user_id):
        """Delete a user container"""
        try:
            container_name = f"idea-{user_id}"
            
            # Stop container
            subprocess.run(['docker', 'stop', container_name], capture_output=True)
            
            # Remove container
            result = subprocess.run(['docker', 'rm', container_name], capture_output=True, text=True)
            if result.returncode != 0:
                return {'success': False, 'error': result.stderr}
            
            return {'success': True, 'message': f'User {user_id} deleted'}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def _verify_password(self, user_id, password):
        """Verify user password - simplified check"""
        # For now, accept default password or any non-empty password
        # In production, you'd check against stored passwords
        return len(password) >= 4

    def log_message(self, format, *args):
        print(f"[API] {args[0]}")

if __name__ == '__main__':
    port = int(os.environ.get('API_PORT', 8080))
    server = HTTPServer(('0.0.0.0', port), APIHandler)
    print(f"API server running on port {port}")
    server.serve_forever()
