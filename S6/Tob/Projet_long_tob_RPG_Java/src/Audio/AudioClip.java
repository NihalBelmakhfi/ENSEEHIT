package Audio;
import javax.sound.sampled.*;

public abstract class AudioClip {
	private final Clip clip;
	
	public AudioClip(Clip clip) {
		this.clip = clip;
		clip.start();
	}
	
	public void update(GameSettings gameSettings) {
		final FloatControl control = (FloatControl) clip.getControl(FloatControl.Type.MASTER_GAIN);
		control.setValue(getVolume(gameSettings));
	}
	
	protected abstract float getVolume(GameSettings gameSettings);
	
	public boolean hasFinishedPlaying() {
		return !clip.isRunning();
	}
	
	public void cleanUp() {
		clip.close();
	}
	}

