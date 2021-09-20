from flask import (
    Blueprint, flash, g, redirect, render_template, request, url_for
)
from .models import NotesModel
from . import db
import time


bp = Blueprint('notes', __name__)


@bp.route('/')
def index():
    notes = NotesModel.query.filter_by(done="0").all()
    done = NotesModel.query.filter_by(done=1).all()
    return render_template('notes/index.html', notes=notes, done=done)


@bp.route('/create', methods=('POST',))
def create():

    text = request.form['text']
    error = None

    if not text:
        error = 'text is required.'

    if error is not None:
        flash(error)
    else:
        new_note = NotesModel(created=int(time.time()), text=text)
        db.session.add(new_note)
        db.session.commit()
        return redirect(url_for('notes.index'))

# These should be a POST, using GET as a workaround to avoid some display problems in CSS


@bp.route('/<int:id>/delete', methods=('GET',))
def delete(id):
    note = NotesModel.query.get_or_404(id)
    db.session.delete(note)
    db.session.commit()
    return redirect(url_for('notes.index'))


@bp.route('/<int:id>/done', methods=('GET',))
def done(id):
    note = NotesModel.query.get_or_404(id)
    note.done = 1 - note.done
    db.session.add(note)
    db.session.commit()
    return redirect(url_for('notes.index'))
