import React from "react";
import { Player, Players } from "../helpers/Player";

import './WarmupScene.scss';

interface Props {
    rupProgress: number;
    clientPlayer: Player;
    players: Players;
}

const WarmupScene: React.FC<Props> = ({ rupProgress, clientPlayer }) => {
    return (
        <>
            <div id="pageWarmup" className="page">

                <div id="tutorial">
                    <div className="keyHolder keyF9">
                        <span>T</span>
                        <h3>Teams</h3>
                    </div>
                    <div className="keyHolder keyF10">
                        <span>I</span>
                        <h3>Loadouts</h3>
                    </div>
                </div>

                <div className={"infoBox " + ((clientPlayer !== undefined && clientPlayer.isReady) ? "ready" : "notReady")}>
                    <div className="rupProgress" style={{width: rupProgress + "%"}}></div>
                    {(clientPlayer !== undefined && clientPlayer.isReady)
                    ?
                        <>
                            <h1>You are ready!</h1>
                            <h3>Hold <span className="key">{"{Interact}"}</span> to Un-Ready.</h3>
                        </>
                    :
                        <>
                            <h1>You are not ready!</h1>
                            <h3>Hold <span className="key">{"{Interact}"}</span> to Ready-Up.</h3>
                        </>
                    }
                </div>
            </div>
        </>
    );
};

export default WarmupScene;
