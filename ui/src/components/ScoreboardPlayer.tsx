import React from "react";
import { useLang } from "../context/Lang";
import { GameStates } from "../helpers/GameStates";
import { Player } from "../helpers/Player";

interface Props {
    player: Player;
    gameState: GameStates;
}

const ScoreboardPlayer: React.FC<Props> = ({ player, gameState }) => {
    const { t } = useLang();
    
    return (
        <>
            <div className={"playerHolder " + (player.isDead ? 'isDead' : 'isAlive')}>
                <div className="playerPing">{player.ping??0}</div>

                {(gameState === GameStates.Warmup) &&
                    <div className={"playerReady " + (player.isReady ? 'ready' : 'wait')}>
                        {player.isReady ? t('ready') : t('waiting')}
                    </div>
                }

                <div className="playerName">{player.name??' - '}</div>
                <div className="playerKill">{player.kill??' - '}</div>
                <div className="playerDeath">{player.death??' - '}</div>
            </div>
        </>
    );
};

export default ScoreboardPlayer;
