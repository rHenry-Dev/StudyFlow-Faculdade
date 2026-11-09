from src.interface import AulaMindWindow
from PySide6.QtWidgets import QApplication
import sys


def main() -> int:
    app = QApplication(sys.argv)
    app.setStyle("Fusion")
    window = AulaMindWindow()
    window.show()
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
