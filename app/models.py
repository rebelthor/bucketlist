from . import db


class NotesModel(db.Model):
    __tablename__ = 'notes'

    id = db.Column(db.Integer, primary_key=True)
    created = db.Column(db.Integer())
    text = db.Column(db.String())
    done = db.Column(db.Integer(), default=0)

    def __init__(self, created, text):
        self.created = created
        self.text = text

    def __repr__(self):
        return f"<Note {self.id}>"
