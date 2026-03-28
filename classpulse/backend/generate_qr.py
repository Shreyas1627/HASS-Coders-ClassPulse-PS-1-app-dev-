import socket
import qrcode
import os

def get_local_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # doesn't even have to be reachable
        s.connect(('10.255.255.255', 1))
        IP = s.getsockname()[0]
    except Exception:
        IP = '127.0.0.1'
    finally:
        s.close()
    return IP

def generate_qr():
    ip = get_local_ip()
    port = 8000
    url = f"http://{ip}:{port}/student_web/session.html"
    
    print(f"Detected IP: {ip}")
    print(f"Generating QR Code for: {url}")
    
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(url)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")
    
    # Save to webpage folder
    output_path = os.path.join(os.path.dirname(__file__), "webpage", "offline_qr.png")
    img.save(output_path)
    print(f"QR Code saved to: {output_path}")

if __name__ == "__main__":
    generate_qr()
